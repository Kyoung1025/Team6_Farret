# 자동화 경계

무엇이 코드로 자동이고 무엇이 사람 손인지 정리한다. 실제로 해 본 뒤 틀린 부분을 고친다.

## 자동

| 단계 | 도구 | 메모 |
|---|---|---|
| 패키지, 시간 동기화, Docker | Ansible (`common`, `docker`) | |
| WireGuard 키 생성, wg0.conf, 터널 활성화 | Ansible (`wireguard`) | 키는 VM 안에서만 만든다. 재시작 대신 `wg syncconf` |
| 방화벽 (SSH는 관리자 대역만, 80, k3s 대역) | Ansible (`firewalld`) | |
| DB compose, 옛 서비스 `legacy` 프로파일 | Ansible (`db_stack`) | |
| k3s 설치, kubeconfig | Ansible (`k3s`) | 버전 고정 |
| ECR Secret, 6시간 갱신 | Ansible (`ecr_pull`) + cron | |
| pod → DB 접속 확인 | Ansible (`k8s_app` 첫 단계) | 안 되면 배포를 멈춘다. `--tags dbcheck` |
| pretix, redis, nginx 배포와 재시작 | Ansible (`k8s_app`) | 설정이 바뀐 경우만 재시작 |
| nginx Service 타입 (ClusterIP ↔ LoadBalancer) | Ansible (`nginx_service_type`) | |
| 업로드 파일 복사 (docker 볼륨 → PVC) | Ansible (`-e migrate_data=true`일 때만) | 덮어쓰는 작업이라 실행 시점은 사람이 정한다 |
| 백업 (DB 덤프 + PVC → S3, 매시간) | Ansible (`backup`) + cron | |
| 재부팅 뒤 복구 | systemd (k3s, docker, wg-quick) | 10/16 재부팅으로 확인 |
| AWS 리소스 | Terraform | 코드와 import는 준비, 아직 apply 전 |

## 일부러 수동

| 단계 | 이유 |
|---|---|
| VM 생성, OS 설치 | 가상화 자동화 도구(Vagrant 등)는 이번 범위에서 빠졌다 |
| 공유기 포트포워딩, 공인 IP 확인 | 장비 관리 화면이다 |
| 처음 SSH 키 배포 | 첫 접속은 키가 없다 |
| VM의 AWS 자격 증명 (백업용 `default`, `ecr-pull`) | 키는 코드에 넣지 않는다 |
| vault 비밀번호 전달 | 저장소 밖에서 |
| WireGuard 공개키를 허브 peer에 등록, VM 22 허용 | 두 시스템을 이어 주는 신뢰 단계라 사람이 확인한다 |
| AWS 값(EIP, ALB DNS, 허브 공개키)을 Ansible 변수에 반영 | `terraform output` 값을 옮긴다. 두 도구를 직접 엮지 않는다 |
| 전환 시점 (docker 정지 → 80 인계) | 되돌리기 판단이 필요하다. 시간대를 정해 함께 한다 |
| 옛 docker 컨테이너, 이미지 삭제 | 삭제는 되돌리기 어렵다. 안정 확인 후 한다 |
| DB 복원 | 상태(데이터)는 코드가 아니다 |
| 계정 수준 설정 (MFA, Budgets 알람) | 계정에 1회성 |

## 아직 수동 (코드로 옮길 수 있음)

| 단계 | 옮길 곳 | 담당 |
|---|---|---|
| ALB 온프렘 대상 그룹(`pretix-onprem-tg`)과 헬스체크 설정 | Terraform alb 모듈 | AWS 담당 |
| cAdvisor를 k3s containerd에 연결 | Ansible `exporters` | 모니터링 방식이 정해진 뒤 |

## 범위 밖

| 단계 | 이유 |
|---|---|
| 도메인, HTTPS | 도메인이 정해진 다음 |

## 실제로 해 본 결과 (10/15~16)

- docker → k3s 전환은 Ansible(`ecr`, `k8s_app`)과 수동(Service 전환, 업로드 파일 복사)으로 끝냈다. 롤 재실행은 `changed=0`. 그 뒤 수동이던 두 가지도 롤로 옮겼다.
- pretix 자원은 compose 값을 그대로 옮기면 안 됐다. CPU 0.5에서는 시작 중 gunicorn이 `WORKER TIMEOUT`을 반복했고, 메모리 1Gi에서는 OOMKilled. 지금 CPU 1, 메모리 1536Mi.
- 전환 중 손으로 바꾼 값(CPU, Service 타입)은 전부 코드에 다시 반영했다. k3s 설정을 VM에서 직접 바꾸면 다음 롤 실행 때 되돌아간다.
- 백업은 전환 뒤 `pretix_data_from: k3s`로 바꿔 PVC를 백업한다. 안 바꾸면 성공 알림은 오는데 멈춘 docker 볼륨만 백업된다.
- VM 재부팅(10/16 아침) 뒤 k3s, DB, WireGuard가 사람 손 없이 다시 올라왔다.
- pretix는 `pretix.cfg`의 url에 적힌 이름으로 온 요청만 받는다(그 외는 400). ALB 헬스체크는 IP로 오므로 k3s nginx가 `/healthcheck/`만 이름을 바꿔 넘긴다.
- 남은 것: k3s가 SELinux 모드로 돌지 않음(`--selinux` 없음), 옛 docker 컨테이너 정리, 모니터링(⑧-6).
