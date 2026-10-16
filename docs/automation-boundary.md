# 자동화 경계

코드로 하는 것과 사람이 하는 것. 해 보고 틀리면 고친다.

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
| VM 생성, OS 설치 | Vagrant 같은 도구는 이번 범위에서 뺐다 |
| 공유기 포트포워딩, 공인 IP | 장비 관리 화면 |
| 처음 SSH 키 배포 | 첫 접속엔 키가 없다 |
| VM의 AWS 키 (`default`, `ecr-pull`) | 키는 코드에 안 넣는다 |
| vault 비밀번호 전달 | 저장소 밖에서 |
| 허브에 WireGuard peer 등록, VM 22 허용 | 두 시스템을 잇는 단계라 사람이 확인 |
| AWS 값(EIP, ALB DNS, 허브 공개키)을 Ansible 변수에 옮기기 | `terraform output`을 보고 옮긴다 |
| 전환 시점 (docker 정지 → 80 인계) | 되돌릴지 판단해야 한다 |
| 옛 docker 컨테이너, 이미지 삭제 | 지우면 못 되돌린다 |
| DB 복원 | 데이터는 코드가 아니다 |
| MFA, Budgets 알람 | 계정에 한 번 |
| node_exporter, cAdvisor | 모니터링 담당이 VM에서 직접 관리한다 |
| 도메인, HTTPS | 이번 범위 밖 |

## 해 보니 (10/15~16)

- docker → k3s 전환은 `ecr`, `k8s_app`으로 하고 Service 전환과 업로드 파일 복사만 손으로 했다. 그 둘도 지금은 롤에 있다. 재실행 `changed=0`.
- compose 자원 값을 그대로 쓰면 pretix가 안 뜬다. CPU 0.5에서는 `WORKER TIMEOUT` 반복, 메모리 1Gi에서는 OOMKilled. 지금 CPU 1, 메모리 1536Mi.
- 전환 중 손으로 바꾼 값(CPU, Service 타입)은 코드에 다시 넣었다. VM에서만 바꾸면 다음 실행 때 되돌아간다.
- 백업은 `pretix_data_from: k3s`로 바꿔야 PVC를 백업한다. 안 바꾸면 성공 알림은 오는데 멈춘 docker 볼륨만 올라간다.
- pretix는 `pretix.cfg` url에 적힌 이름으로 온 요청만 받는다(그 외 400). ALB 헬스체크는 IP로 오니까 k3s nginx가 `/healthcheck/`만 이름을 바꿔 넘긴다.
- 남은 것: k3s가 SELinux 모드가 아님, 옛 docker 정리, 모니터링(⑧-6).
