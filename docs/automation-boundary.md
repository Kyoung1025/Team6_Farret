# 자동화 경계

무엇이 코드로 자동이고 무엇이 사람 손인지 정리한다. 실제로 해 본 뒤 틀린 부분을 고친다.

| 단계 | 자동 / 수동 | 이유 |
|---|---|---|
| VM 생성·OS 설치 | 수동 | 가상화 자동화 도구(Vagrant 등)는 이번 범위에서 빠졌다 |
| 공유기 포트포워딩·공인 IP 확인 | 수동 | 장비 관리 화면이다 |
| 처음 SSH 키 배포 | 수동 | 첫 접속은 키가 없다 |
| 패키지·Docker·firewalld·WireGuard 설정 | 자동 (Ansible) | 반복 가능, 확인 가능 |
| k3s 설치와 매니페스트 적용 | 자동 (Ansible) | 같은 이유 |
| WireGuard 공개키를 AWS peer에 등록 | 수동 (알려 주고 확인) | 두 시스템을 이어 주는 신뢰 단계. Terraform 출력값과 Ansible 변수를 사람이 옮겨 적는다 |
| AWS 정보(Elastic IP, ALB DNS, 서버 공개키)를 `vars.yml`에 반영 | 수동 (복사) | `terraform output` 값을 옮긴다 |
| DB 데이터 복원 | 수동 | 상태(데이터)는 코드가 아니다 |
| `pretix-data` 복사 (docker 볼륨 → PVC) | 자동 (Ansible, `-e migrate_data=true`일 때만) | 덮어쓰는 작업이라 실행 시점은 사람이 정한다 |
| VM의 AWS CLI 자격 증명 설정 | 수동 | 키는 코드에 넣지 않는다 |
| vault 비밀번호 전달 | 수동 | 저장소 밖에서 |
| AWS 리소스 | 자동 (Terraform) | 코드와 import는 준비, 아직 apply 전 |
| 계정 수준 설정 (MFA, Budgets 알람) | 수동 | 계정에 1회성 |
| 도메인·HTTPS | 범위 밖 | 도메인이 정해진 다음 |
| 제어 노드 WireGuard peer 등록(허브)과 VM 22 허용 | 수동 (알려 주고 확인) | 신뢰 단계라서 사람이 확인한다 |
| k3s 전환 시점 (docker 정지 → 80 포트 인계) | 수동 | 시간대를 정해 함께 한다. 되돌리기 판단이 필요하다 |
| 기존 docker 컨테이너·이미지 삭제 | 수동 | 삭제는 되돌리기 어렵다. 안정 확인 후 한다 |
| ECR 읽기 전용 키를 VM에 등록 (`aws configure --profile ecr-pull`) | 수동 | 키는 코드에 넣지 않는다. 이후 Secret 갱신은 cron(6시간)이 한다 |
| pod → DB 접속 확인 | 자동 (Ansible, `k8s_app` 첫 단계) | 안 되면 배포를 멈춘다. 따로 볼 때는 `--tags dbcheck` |
| nginx Service를 LoadBalancer로 바꾸기 | 자동 (Ansible, `nginx_service_type`) | 이번에는 손으로 `kubectl patch` 했다가 코드에 반영했다. 다음부터는 변수로 한다 |
| ALB 대상 그룹 헬스체크 설정 | 수동 (AWS 콘솔) | 아직 Terraform 코드에 `pretix-onprem-tg`가 없다 |

## 실제로 해 본 결과 (10/15~16)

- docker → k3s 전환은 Ansible(`ecr`, `k8s_app`) + 수동(Service 전환, 업로드 파일 복사)으로 끝냈다. 롤 재실행은 `changed=0`.
- pretix 자원은 compose 값을 그대로 옮기면 안 됐다. CPU 0.5에서는 시작 중 gunicorn이 `WORKER TIMEOUT`을 반복했고, 메모리 1Gi에서는 OOMKilled. 지금 CPU 1, 메모리 1536Mi.
- 전환 중 손으로 바꾼 값(CPU, Service 타입)은 전부 코드에 다시 반영했다. k3s 설정을 VM에서 직접 바꾸면 다음 롤 실행 때 되돌아간다.
- 백업은 전환 뒤 `pretix_data_from: k3s`로 바꿔 PVC를 백업한다. 안 바꾸면 성공 알림은 오는데 멈춘 docker 볼륨만 백업된다.
- VM 재부팅(10/16 아침) 뒤 k3s, DB, WireGuard가 사람 손 없이 다시 올라왔다.
- pretix는 `pretix.cfg`의 url에 적힌 이름으로 온 요청만 받는다(그 외는 400). ALB 헬스체크는 IP로 오므로 k3s nginx가 `/healthcheck/`만 이름을 바꿔 넘긴다.
- 남은 것: k3s가 SELinux 모드로 돌지 않음(`--selinux` 없음), 옛 docker 컨테이너 정리, 모니터링(⑧-6).
