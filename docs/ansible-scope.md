# Ansible 범위

온프렘 VM(Rocky, 10.10.0.2)에서 Ansible 코드로 관리하는 것과 안 하는 것. 10/21 기준이고, 이날 전체 롤을 `--check --diff`로 돌려 VM과 코드가 같은 걸 확인했다.

언제 무엇을 사람이 하는지(절차)는 `docs/automation-boundary.md`에 있고, 이 문서는 "코드에 들어 있나"만 다룬다.

## 코드로 관리하는 것

| 롤 | 하는 일 | 메모 |
|---|---|---|
| `common` | 기본 패키지, chrony(시간 동기화), SELinux 상태 확인, AWS CLI | SELinux는 바꾸지 않고 상태만 찍음 |
| `docker` | Docker 저장소, Docker와 compose 플러그인, 서비스 | DB 컨테이너용 |
| `wireguard` | WireGuard 설치, 키 생성(없을 때만), `wg0.conf`, wg-quick | 키는 VM 안에서만 만든다. 바꿀 때는 재시작 대신 `wg syncconf` |
| `firewalld` | SSH는 관리자 대역만, 80 열기, wg0과 k3s 대역(10.42, 10.43)을 trusted로 | |
| `db_stack` | `/root/stack/docker-compose.yml`, DB 기동 | 옛 redis, pretix, nginx 컨테이너는 `legacy` 프로파일로 꺼 둠 |
| `k3s` | k3s 설치(버전 고정, traefik 끔), kubeconfig, 노드 Ready 대기 | |
| `ecr_pull` | namespace `pretix`, ECR 로그인 Secret, 6시간마다 갱신하는 cron | |
| `k8s_app` | pod → DB 접속 확인, `pretix.cfg` Secret, redis·pretix·nginx 배포 | 설정이 바뀐 경우만 재시작 |
| `k8s_app` | pretix 이미지(digest 고정), 메모리 한도 2000Mi, nginx 헬스체크 Host | |
| `k8s_app` | 업로드 파일 복사(docker 볼륨 → PVC) | `-e migrate_data=true`를 줄 때만. 덮어써서 |
| `backup` | `/root/backup.sh`, 매시 정각 cron | DB 덤프(`-Fc`)와 업로드 파일을 S3로 |

`pretix.cfg`는 템플릿(`pretix.cfg.j2`)으로 통째로 만들어 k3s Secret으로 넣는다. 비밀번호와 django secret은 vault. 그래서 빈 VM에서도 `site.yml` 한 번으로 같은 설정이 나온다.

## 코드에 없는 것

| 대상 | 이유 |
|---|---|
| VM 생성, OS 설치 | Vagrant로 만들었다. Ansible은 OS가 깔린 뒤부터 |
| 공유기 포트포워딩, 공인 IP | 장비 관리 화면에서만 바꿀 수 있다 |
| 처음 SSH 키 등록 | Ansible이 접속하려면 키가 먼저 있어야 해서 |
| VM의 AWS 키 (`default`, `ecr-pull` 프로필) | 비밀값. 사람이 `aws configure`로 넣었다 |
| vault 비밀번호 | 저장소 밖에서 따로 전달 |
| DB 비밀번호, 메일 비밀번호 값 | 코드에는 vault로 암호화해서 있다. 값 자체는 평문으로 안 둔다 |
| DB 안의 데이터, 복원 | 데이터는 코드가 아니다. 복원은 백업 파일로 사람이 한다 |
| 백업이 올라가는 S3 버킷 | AWS 쪽 리소스라 Ansible 범위 밖. Terraform에도 아직 없음 |
| 허브 쪽 peer 등록 | AWS 허브의 `wg0.conf` 본문은 SSM 파라미터에 있다. 두 시스템을 잇는 단계라 사람이 확인하고 넣는다 |
| node_exporter, cAdvisor, Prometheus, Grafana | 모니터링 담당이 VM과 모니터링 VM에서 직접 관리한다 |
| 모니터링 VM (10.10.0.3) | 다른 서버. 이 플레이북의 대상이 아니다 |
| docker → k3s 전환 시점, 옛 컨테이너·이미지 삭제 | 되돌릴지 사람이 판단해야 하고, 지우면 못 되돌린다 |
| `/root/k8s`의 `*-secondary.yaml`, `secret-pretix-cfg.yaml` | 10/19에 손으로 만든 파일. Ansible이 만든 게 아니라 지우지도 않는다. 담당자 확인 후 정리 예정 (`secret-pretix-cfg.yaml`은 비밀번호가 평문) |
| `/root/dbwatch.sh` | 시나리오 때 DB를 보려고 만든 개인 도구 |

## 알고 있어야 할 것

- VM을 손으로 고치면 다음 실행 때 코드 값으로 되돌아간다. 급해서 고쳤다면 같은 값을 코드에도 넣는다. 10/20에 메모리 한도, 이미지 태그, nginx 설정을 손으로 바꿨다가 10/21에 코드로 맞췄다.
- 이미지는 태그가 아니라 digest로 적는다. ECR에 `latest` 태그가 없어서, VM이 `:latest`를 쓰다가 캐시가 비자 pod가 못 떴다.
- ECR 토큰은 12시간짜리이고 cron은 6시간마다 돈다. VM이 오래 꺼져 있다 켜지면 토큰이 만료돼 있을 수 있다. 그때는 `/root/k8s/ecr-secret.sh`를 한 번 돌린다.
- 미리보기에서 `docker : Docker 저장소`는 항상 changed로 나온다. 미리보기 때는 파일을 안 받아서 비교를 못 하는 것뿐이고 실제 실행에서는 바뀌지 않는다.
- 같은 VM에 여러 사람이 동시에 실행하지 않는다.
