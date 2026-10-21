# Farret: 마감에도 안 멈추는 하이브리드 인프라

대입 원서 접수처럼 마감 직전에 접속이 몰리는 서비스를 AWS와 온프렘에 같이 올려 둔 프로젝트다. 서비스는 [pretix](https://pretix.eu)(티켓·접수 시스템)로 시연한다.

- 평소에는 AWS가 받는다. 몰리면 ASG가 서버를 늘린다.
- AWS가 통째로 죽으면 CloudWatch 경보를 받은 Lambda가 ALB 가중치를 온프렘으로 돌린다.
- DB는 온프렘 PostgreSQL 한 대를 양쪽이 같이 쓴다. AWS 앱은 WireGuard 터널로 붙는다.

```
                         사용자
                           │
                ALB (가중치 AWS 100 : 온프렘 0)
                ├──────────────────────────┐
                ▼                          ▼  (장애 때 0 : 100)
     AWS ASG: nginx + pretix + redis     WireGuard 허브 (AWS, ASG 1대)
                │                          │
                └──── WireGuard 터널 ───────┤
                                           ▼
                        온프렘 VM 10.10.0.2 (Rocky)
                        ├─ k3s: nginx → pretix → redis
                        └─ docker: PostgreSQL ── 매시간 백업 → S3
```

## 폴더

```
.
├── ansible/                온프렘 VM 설정
│   ├── site.yml            롤 9개를 순서대로
│   ├── inventory/          대상 VM (10.10.0.2)
│   ├── group_vars/all/     변수, vault(암호화된 비밀번호)
│   └── roles/              common, docker, wireguard, firewalld, db_stack,
│                           k3s, ecr_pull, k8s_app, backup
├── terraform/              AWS 리소스
│   ├── main.tf             모듈 조립, state는 S3
│   ├── imports.tf          콘솔로 만든 걸 가져오는 블록 (첫 apply 뒤 삭제)
│   ├── global/s3/          state 버킷
│   └── modules/
│       ├── network/        VPC, 서브넷, 라우팅, 보안그룹
│       ├── alb/            ALB, 대상 그룹(AWS, 온프렘), 가중치 리스너, WAF
│       ├── app/            시작 템플릿, ASG, 확장 정책, ECR, Secrets Manager
│       ├── gateway/        NAT 인스턴스, WireGuard 허브 ASG
│       └── monitoring/     SNS, 경보, 대시보드 2개, Lambda 2개
├── monitoring/
│   ├── design.md           경보·대시보드 설계
│   ├── discord-notifier/   경보 → 디스코드 Lambda
│   └── failover/           경보 → ALB 가중치 전환 Lambda
└── docs/
    ├── automation-boundary.md   자동으로 되는 것, 사람이 하는 것
    ├── ansible-scope.md         Ansible 코드에 있는 것, 없는 것
    ├── terraform-scope.md       Terraform 코드에 있는 것, 없는 것
    └── branch-rules.md          브랜치, PR 규칙
```

폴더마다 README가 있다. 실행 방법은 `ansible/README.md`, 모듈 설명은 `terraform/modules/*/README.md`.

## 무엇이 자동이고 무엇이 손으로 하나

자세한 건 `docs/automation-boundary.md`. 줄이면 이렇다.

**코드로 만든다**

| 대상 | 도구 |
|---|---|
| 온프렘 VM: 패키지, Docker, WireGuard, 방화벽, DB, k3s, pretix 배포, 백업 cron | Ansible |
| AWS: 네트워크, ALB, ASG, NAT, WireGuard 허브, 경보, 대시보드, Lambda | Terraform |

**돌아가면서 알아서 한다**

| 상황 | 하는 것 |
|---|---|
| AWS에 부하가 몰림 | ASG가 CPU 60% 기준으로 서버를 늘리고 줄임 |
| AWS 서버가 전부 죽음 | 경보 → Lambda가 가중치를 온프렘으로 (온프렘이 정상일 때만) |
| 경보가 울림 | 메일, 디스코드로 알림 |
| WireGuard 허브가 죽음 | ASG가 새로 띄우고, 부팅 스크립트가 EIP와 터널 경로를 가져감 |
| 매시 정각 | DB 덤프와 업로드 파일을 S3로 |
| VM 재부팅 | k3s, DB, WireGuard가 다시 뜸 |

**사람이 한다**

| 대상 | 이유 |
|---|---|
| 온프렘 → AWS 복귀 (가중치 100 : 0) | AWS가 다시 정상인지 보고 돌린다. 자동이면 오락가락할 수 있음 |
| DB 복원 | 백업 파일로 직접. 절차는 노션 시나리오 문서 |
| 비밀값 넣기 (vault 비밀번호, AWS 키, WireGuard 키, tfvars) | 저장소에 안 올린다 |
| VM 생성, 공유기 설정, 처음 SSH 키 | 코드가 닿기 전 단계 |
| Terraform 첫 apply | import 70개라 팀이 시간을 맞춰서 |

## 쓰는 값

| 항목 | 값 |
|---|---|
| 접속 주소 | `http://pretix-demo-alb-807412016.ap-northeast-2.elb.amazonaws.com` (도메인 없음) |
| 리전 | ap-northeast-2 (서울) |
| 온프렘 VM | 10.10.0.2 (WireGuard 주소) |
| WireGuard 대역 | 10.10.0.0/24 |
| state 버킷 | `pretix-demo-tfstate-994114886472` |
| 백업 버킷 | `pretix-demo-backup-994114886472` |

## 규칙

- `main`에 직접 푸시하지 않는다. 브랜치에서 작업하고 PR로 올려 한 명 이상이 본다. (`docs/branch-rules.md`)
- 비밀값(DB 비밀번호, AWS 키, vault 비밀번호, tfvars, `.pem`)은 올리지 않는다. 실수로 올렸으면 지우고 끝내지 말고 키를 바꾼다.
- VM이나 AWS 콘솔에서 직접 고쳤으면 같은 값을 코드에도 넣는다. 안 그러면 다음 실행 때 되돌아간다.
- 적용 전에 미리 본다. Ansible은 `--check --diff`, Terraform은 `plan`.
- Terraform 코드를 고치면 `terraform fmt`를 돌린다.
