# 자동화 경계

무엇이 코드나 자동 동작으로 되고, 무엇을 사람이 하는지. 10/21 기준.

코드에 무엇이 들어 있는지는 `docs/ansible-scope.md`, `docs/terraform-scope.md`에 따로 있다.

## 코드로 만드는 것

### 온프렘 VM (Ansible)

| 단계 | 롤 | 메모 |
|---|---|---|
| 패키지, 시간 동기화, AWS CLI | `common` | |
| Docker | `docker` | DB 컨테이너용 |
| WireGuard 키, wg0.conf, 터널 | `wireguard` | 키는 VM 안에서만 만든다. 반영은 `wg syncconf` |
| 방화벽 | `firewalld` | SSH는 관리자 대역만, 80, k3s 대역 |
| DB compose | `db_stack` | 옛 pretix, redis, nginx는 `legacy` 프로파일로 꺼 둠 |
| k3s 설치 | `k3s` | 버전 고정 |
| ECR 로그인 Secret, 6시간마다 갱신 | `ecr_pull` | |
| pod → DB 접속 확인 | `k8s_app` | 안 되면 배포 중단. `--tags dbcheck` |
| pretix, redis, nginx 배포 | `k8s_app` | 설정이 바뀌었을 때만 재시작 |
| 업로드 파일 복사 (docker 볼륨 → PVC) | `k8s_app` | 덮어써서 `-e migrate_data=true`를 줄 때만 |
| 백업 스크립트, 매시 cron | `backup` | |

### AWS (Terraform)

| 단계 | 모듈 | 메모 |
|---|---|---|
| VPC, 서브넷, 라우팅, 보안그룹 | `network` | |
| ALB, 대상 그룹(AWS, 온프렘), 가중치 리스너, WAF | `alb` | 가중치는 처음 만들 때만 코드 값(100 : 0) |
| 시작 템플릿, ASG, 확장 정책 | `app` | |
| NAT 인스턴스, WireGuard 허브 ASG | `gateway` | |
| SNS, 경보 3개, 대시보드 2개, Lambda 2개 | `monitoring` | |

코드와 import는 있고 아직 apply 전이다. 10/21 `plan`에서 실제와 같은 걸 확인했다.

## 돌아가면서 알아서 하는 것

| 상황 | 동작 | 메모 |
|---|---|---|
| AWS에 부하가 몰림 | ASG가 CPU 60% 기준으로 늘리고 줄임 | 늘리기는 약 3~4분, 줄이기는 15분 넘게 걸림 |
| AWS 서버가 전부 죽음 | 경보 `aws-unhealthy` → SNS → Lambda `failover`가 가중치 0 : 100 | 온프렘이 healthy일 때만. 시나리오 2에서 경보까지 약 10분, 전환은 1초 |
| 경보가 울림 | 메일, 디스코드 알림 | 정상으로 돌아올 때는 안 보냄 |
| WireGuard 허브가 죽음 | ASG가 새로 띄우고 부팅 스크립트가 EIP, 터널 경로를 가져감 | |
| 매시 정각 | DB 덤프, 업로드 파일 → S3 | |
| ECR 토큰 만료 전 | 6시간마다 갱신 | VM이 오래 꺼져 있었으면 만료돼 있을 수 있음 |
| VM 재부팅 | systemd로 k3s, DB, WireGuard가 다시 뜸 | |

## 사람이 하는 것

| 단계 | 이유 |
|---|---|
| VM 생성, OS 설치 | Vagrant로 만듦. Ansible은 그다음부터 |
| 공유기 포트포워딩, 공인 IP | 장비 관리 화면에서만 |
| 처음 SSH 키 배포 | 첫 접속엔 키가 없음 |
| VM의 AWS 키 (`default`, `ecr-pull`) | 키는 코드에 안 넣음 |
| vault 비밀번호 전달 | 저장소 밖에서 |
| `terraform.tfvars` 작성 (공인 IP, 웹훅, django secret 등) | 비밀값이라 각자 PC에 |
| WireGuard 키, wg0.conf 본문 (SSM `/pretix/wg/*`) | 비밀값. 허브가 부팅할 때 읽어 감 |
| 허브에 peer 추가 | 두 시스템을 잇는 단계라 사람이 확인 |
| AWS 값(EIP, ALB 주소)을 Ansible 변수에 옮기기 | `terraform output`을 보고 옮긴다 |
| 온프렘 → AWS 복귀 (가중치 100 : 0) | AWS가 다시 healthy인지 보고 돌린다. 자동이면 오락가락할 수 있음 |
| 시작 템플릿 기본 버전 바꾸기, 인스턴스 교체 | Terraform은 새 버전만 만든다. 바꿀 시점은 사람이 정함 |
| Terraform 첫 apply, 이후 `imports.tf` 삭제 | import 70개라 팀이 시간을 맞춰서 |
| docker → k3s 전환 시점, 옛 컨테이너 삭제 | 되돌릴지 직접 판단해야 하고, 지우면 못 되돌림 |
| DB 복원 | 데이터는 코드가 아니다. 백업 파일로 직접 |
| 모니터링 스택 (Prometheus, Grafana, exporter) | 모니터링 담당이 VM에서 직접 관리 |
| MFA, Budgets 경보 | 계정에 한 번 |
| 도메인, HTTPS | 아직 없음 |
