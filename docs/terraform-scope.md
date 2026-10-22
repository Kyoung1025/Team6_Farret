# Terraform 범위

AWS 쪽에서 Terraform 코드로 관리하는 것과 안 하는 것.  (import 70, 추가 0, 삭제 0).

처음에 콘솔로 만든 걸 `imports.tf`로 가져오는 방식이라, apply하기 전까지는 코드만 있고 state에는 아무것도 없다. 
apply 후 `imports.tf`지워야함

## 코드로 관리하는 것

| 모듈 | 리소스 | 메모 |
|---|---|---|
| `global/s3` | state 버킷 (버전 관리, 암호화, 공개 차단) | 메인 코드와 state를 따로 둠. 메인을 destroy해도 남음 |
| `network` | VPC, 서브넷 4개(public 2, app 2), IGW, 라우팅 테이블, S3 엔드포인트 | |
| `network` | 보안그룹 4개(alb, app, nat, wg)와 규칙 | SSH는 안 엶. SSM으로 접속 |
| `alb` | ALB, 80 리스너, 대상 그룹 2개(AWS 앱, 온프렘), 온프렘 대상 10.10.0.2 | |
| `alb` | WAF (관리형 규칙 2개, Count) | 차단은 안 하고 기록만 |
| `app` | 시작 템플릿, ASG(On-Demand 1 + Spot), CPU 60% 확장 정책, 예약 스케일링 | 예약 스케일링은 변수로 켬. 기본은 꺼짐 |
| `app` | ECR 저장소, Secrets Manager 보관함 2개(DB, SMTP) | 보관함만. 값은 아래 참고 |
| `gateway` | NAT 인스턴스, App 라우팅 테이블의 인터넷 경로 | NAT 게이트웨이는 시간당 요금이라 t3.micro로 |
| `gateway` | WireGuard 허브: 시작 템플릿, ASG 1대, EIP, IAM 역할과 정책 | |
| `monitoring` | SNS 토픽, 메일 구독, 디스코드 Lambda | |
| `monitoring` | 자동 전환 Lambda(failover)와 IAM 역할, SNS 구독 | 가중치 변경은 이 리스너에만 허용 |
| `monitoring` | 경보 3개: aws-unhealthy, alb-5xx, target-5xx | |
| `monitoring` | 대시보드 2개: `pretix-demo`(평소 감시), `pretix-demo-test3`(부하테스트) | |

## 코드에 없는 것

| 대상 | 이유 |
|---|---|
| 비밀번호 값 (DB, SMTP) | state 파일에 평문으로 남아서. 보관함만 코드로 만들고 값은 콘솔에서 넣었다 |
| django secret 값 | 같은 이유. 코드는 변수만 받고 값은 각자 `terraform.tfvars`에 넣는다. 나중에 Secrets Manager로 옮길 예정 |
| 디스코드 웹훅 URL | 같은 이유. `terraform.tfvars` |
| WireGuard 서버 개인키, wg0.conf 본문 (SSM `/pretix/wg/*`) | 비밀값. 허브가 부팅할 때 읽어 간다 |
| 허브의 EIP 연결, 10.10.0.0/24 경로 | 허브가 새로 뜰 때마다 부팅 스크립트가 자기한테 붙인다. Terraform이 잡고 있으면 apply할 때마다 서로 되돌림 |
| 리스너 가중치 변경 | 처음 만들 때만 코드 값(100 : 0)을 쓴다. 장애 때 Lambda가 0 : 100으로 바꾸고 복귀는 사람이 해서, apply가 되돌리지 않게 무시하도록 해 둠 |
| ASG 대수 (desired, min) | 확장 정책과 예약 스케일링이 바꾸는 값이라 무시하도록 해 둠 |
| 시작 템플릿 기본 버전 | Terraform은 새 버전을 만들기만 한다. 기본 버전 지정과 인스턴스 교체는 사람이 확인하고 한다 |
| IAM 역할 3개 (app, infra, lambda-alert) | 다른 팀원이 콘솔에서 만들고 권한을 붙여 가며 써 왔다. 이름으로 가져다 쓰기만 하고, 권한 정리가 끝나면 넣는다 |
| ASG 확장 경보 2개 (TargetTracking-…) | 확장 정책이 자동으로 만들고 지운다 |
| 백업 버킷 `pretix-demo-backup-…` | 온프렘 VM이 쓰는 버킷이라 Ansible 백업 롤과 같이 다룬다. 아직 어느 쪽에도 없음 |
| ECR 안의 이미지 | 코드가 아니라 빌드 결과물 |
| 도메인, HTTPS 인증서 | 아직 없음. 지금은 ALB 주소가 공식 주소 |
| MFA, Budgets 경보 | 계정에 한 번만 하는 설정 |
| 인스턴스 1대에 켠 세부 모니터링 | 시나리오 3 때 임시로 켬. 그 인스턴스가 교체되면 없어진다 |
| 예전 단일 WireGuard 인스턴스 (`wireguard-instance`, 정지 상태) | 허브 ASG로 바꾸면서 코드에서 뺐다. 콘솔에서 지우면 됨 |

## terraform.tfvars에 넣는 값

저장소에 안 올라간다(`.gitignore`). 각자 만든다.

| 변수 | 값 |
|---|---|
| `onprem_public_cidr` | 온프렘 공유기 공인 IP `/32` |
| `pretix_public_url` | 지금은 ALB 주소. 도메인이 생기면 `https://tickets.<도메인>` (Ansible `pretix_url`도 같이) |
| `alert_email` | 알림 받을 메일 |
| `discord_webhook_url` | 디스코드 웹훅 |
| `pretix_django_secret` | 시작 템플릿 v8의 `[django] secret` |

## apply 전에 알고 있을 것

- 처음 apply하면 70개를 가져오고, 바뀌는 건 `Project` 태그 추가, Lambda 로그 보관 14일, WireGuard 규칙 설명 정도다. 그래도 `plan`을 한 번 더 보고 한다.
- 실행 위치와 상관없이 state는 S3에 하나다. 두 사람이 동시에 apply하면 락이 막아 준다.
- 콘솔에서 바꾼 게 있으면 `plan`에 차이로 나온다. 코드를 맞추거나 콘솔을 되돌린 뒤 apply한다.
