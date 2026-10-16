# 자동화 경계


## 자동

| 단계 | 도구 | 메모 |
|---|---|---|
| 패키지, 시간 동기화, Docker | Ansible `common`, `docker` | |
| WireGuard 키, wg0.conf, 터널 | Ansible `wireguard` | 키는 VM 안에서만 만든다. 반영은 `wg syncconf` |
| 방화벽 | Ansible `firewalld` | SSH는 관리자 대역만, 80, k3s 대역 |
| DB compose | Ansible `db_stack` | 옛 pretix, redis, nginx는 `legacy` 프로파일 |
| k3s 설치 | Ansible `k3s` | 버전 고정 |
| ECR Secret 갱신 | Ansible `ecr_pull` + cron | 6시간마다 |
| pod → DB 접속 확인 | Ansible `k8s_app` | 안 되면 배포 중단. `--tags dbcheck` |
| pretix, redis, nginx 배포 | Ansible `k8s_app` | 설정이 바뀌었을 때만 재시작 |
| nginx Service 타입 | Ansible `nginx_service_type` | |
| 업로드 파일 복사 (docker 볼륨 → PVC) | Ansible `-e migrate_data=true` | 덮어쓰므로 시점은 사람이 정한다 |
| 백업 (DB 덤프, PVC → S3) | Ansible `backup` + cron | 매시간 |
| 재부팅 뒤 복구 | systemd | 10/16 재부팅 때 확인 |
| ALB, 대상 그룹(AWS, 온프렘), 가중치 | Terraform `alb` | 가중치는 변수. 평소 AWS 100, 온프렘 0 |
| 그 밖의 AWS 리소스 | Terraform | 코드와 import는 있음. 아직 apply 전 |

## 수동

| 단계 | 이유 |
|---|---|
| VM 생성, OS 설치 | Vagrant|
| 공유기 포트포워딩, 공인 IP | 장비 관리 화면 |
| 처음 SSH 키 배포 | 첫 접속엔 키가 없음 |
| VM의 AWS 키 (`default`, `ecr-pull`) | 키는 코드에 안 넣음 |
| vault 비밀번호 전달 | 저장소 밖에서 |
| 허브에 WireGuard peer 등록, VM 22 허용 | 두 시스템을 잇는 단계라 사람이 확인 |
| AWS 값(EIP, ALB DNS, 허브 공개키)을 Ansible 변수에 옮기기 | `terraform output`을 보고 옮긴다 |
| 전환 시점 (docker 정지 → 80 인계) | 되돌릴지 직접 판단해야하기 때문 |
| 옛 docker 컨테이너, 이미지 삭제 | 지우면 못 되돌린다 |
| DB 복원 | 데이터 = 코드 x |
| MFA, Budgets 알람 | 계정에 한 번 |
| node_exporter, cAdvisor | VM에서 직접 관리한다 |
| 도메인, HTTPS |  |

