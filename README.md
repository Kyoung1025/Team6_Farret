# 기본 프로젝트

대입 원서접수 마감 트래픽 폭주 대응 하이브리드 인프라 (온프레미스 + AWS)

평소에는 온프레미스에서 운영하고, 마감 직전 폭주 때만 AWS로 확장한다.

## 폴더 구조

```
.
├── onprem/       온프레미스 VM에서 실행하는 스택
├── terraform/    AWS 인프라 코드
├── docs/         가이드, 규칙, 측정 기록
└── monitoring/   알람·대시보드 설계
```

### `onprem/` — 온프레미스 

Ubuntu VM 한 대에서 Docker Compose로 Nginx, pretix, Redis, PostgreSQL을 실행한다.

| 파일 | 내용 |
|---|---|
| `docker-compose.yml` | 컨테이너 4개 정의. DB 포트는 WireGuard IP(10.10.0.2)에만 게시 |
| `nginx.conf` | 진입점. 버스팅 때 일부 요청을 AWS ALB로 보낸다 |
| `pretix.cfg.example` | pretix 설정 템플릿 (비밀번호 제외) |
| `.env.example` | 환경변수 템플릿. 실제 `.env`는 커밋하지 않는다 |


### `IaC/`

| 파일 | 내용 |
|---|---|
| `main.tf` | Terraform·provider 버전, S3 백엔드, 공통 태그, 모듈 호출 |
| `variables.tf` | 리전, 이름 접두사, VPC·서브넷 대역, 앱 AMI 등 |
| `outputs.tf` | ALB 주소, WireGuard IP, ASG 이름, VPC ID (`terraform output`으로 확인) |
| `imports.tf` | 콘솔로 만든 리소스를 코드와 연결하는 import 블록 |
| `modules/network/` | VPC, 서브넷 4개, IGW, 라우팅 테이블, S3 엔드포인트, 보안그룹 4개 |
| `modules/alb/` | ALB, 리스너, 대상 그룹, WAF |
| `modules/app/` | Launch Template, Auto Scaling 그룹, 확장 정책, 부팅 스크립트, ECR, DB 비밀번호 보관함 |
| `modules/gateway/` | NAT 인스턴스, WireGuard 서버, 탄력적 IP, App 경로 |
| `modules/monitoring/` | SNS 알림, 디스코드 Lambda, 알람 3개, 대시보드 |
| `.terraform.lock.hcl` | provider 버전 고정 (윈도우, 맥, 리눅스) |


### `docs/` — 문서 

| 파일 | 내용 |
|---|---|
| `branch-rules.md` | 브랜치 이름, PR, 리뷰 규칙 |


### `monitoring/` — 모니터링 설계


## 규칙

- 비밀값(DB 비밀번호, WireGuard 개인키, AWS 액세스 키)은 레포에 올리지 않는다
- main에 직접 push하지 않는다. 작업 브랜치 → PR → 리뷰 → merge ([상세](docs/branch-rules.md))
- AWS 리소스 이름은 `pretix-demo-` 접두사, 태그 `Project=pretix-demo`, 리전 `ap-northeast-2(서울)`
