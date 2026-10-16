# ansible

온프렘 VM(Rocky Linux, `10.10.0.2`)을 설정하는 코드다. Docker, 방화벽, WireGuard, k3s를 깔고 pretix, redis, nginx를 k3s에 올린다. DB는 docker compose에 남는다.

```
ansible/
├─ ansible.cfg
├─ requirements.yml            # ansible.posix (firewalld 모듈)
├─ inventory/hosts.yml         # pretix-vm = 10.10.0.2 (WireGuard 주소)
├─ group_vars/all/vars.yml     # 비밀 아닌 값
├─ group_vars/all/vault.yml    # ansible-vault로 암호화 (DB 비밀번호)
├─ site.yml
└─ roles/{common,docker,wireguard,firewalld,db_stack,k3s,ecr_pull,k8s_app,backup}/
```

## 실행 전에 필요한 것

| 항목 | 내용 |
|---|---|
| 제어 노드 | Linux, macOS 또는 Windows WSL2. Ansible은 Windows에서 직접 돌지 않는다 |
| WireGuard | 관리자 peer(10.10.0.128/25)로 터널이 켜져 있어야 한다. `ping 10.10.0.2` |
| SSH 키 | RSA 키. VM이 FIPS 모드라 ed25519는 거부된다. 공개키를 VM `test` 계정에 등록 |
| vault 비밀번호 | `~/.vault-pass` (권한 600). 저장소 밖에서 따로 받는다 |

## 실행

```bash
cd ansible
export ANSIBLE_CONFIG=./ansible.cfg   # /mnt/c 아래는 폴더 권한 때문에 cfg를 무시해서 지정
ansible-galaxy collection install -r requirements.yml
ansible onprem -m ping

ansible-playbook site.yml --check --diff   # 미리보기
ansible-playbook site.yml                  # 실제
ansible-playbook site.yml                  # 한 번 더. changed=0이어야 한다
```

VM 안이 아니라 제어 노드에서 돌린다.

자주 쓰는 태그

| 명령 | 하는 일 |
|---|---|
| `--tags k8s_app` | pretix, redis, nginx 배포 (DB 접속 확인부터) |
| `--tags nginx` | nginx 설정만 |
| `--tags dbcheck` | pod에서 DB(5432) 접속만 확인 |
| `--tags backup` | backup.sh와 cron |
| `--tags ecr` | ECR Secret과 갱신 cron |
| `--tags k8s_app -e migrate_data=true` | 배포 + 업로드 파일 복사 (docker 볼륨 → PVC, 덮어씀) |

`wireguard`는 터널 위에서 터널을 바꾸는 롤이다. 재시작 대신 `wg syncconf`로 반영하지만, 바꿀 게 없으면 `--skip-tags wireguard`로 빼고 돌린다.

## 롤

| 롤 | 하는 일 | 상태 |
|---|---|---|
| common | 기본 패키지, 시간 동기화, SELinux 확인, AWS CLI | 적용 |
| docker | Docker, compose (DB 컨테이너용) | 적용 |
| wireguard | 키 생성(없을 때만), wg0.conf, wg-quick | 적용 |
| firewalld | SSH는 관리자 대역만, 80, wg0과 k3s 대역(10.42, 10.43) trusted | 적용 |
| db_stack | DB compose. redis, pretix, nginx는 `legacy` 프로파일 | 적용 |
| k3s | k3s 설치(버전 고정, traefik 끔), kubeconfig, 노드 Ready 대기 | 적용 |
| ecr_pull | namespace `pretix`, ECR Secret, 6시간 갱신 cron | 적용 |
| k8s_app | DB 접속 확인 → pretix.cfg Secret → redis, pretix, nginx → 바뀐 경우만 재시작 | 적용 |
| backup | backup.sh(DB 덤프 + PVC), 매시간 cron, S3 업로드 | 적용 |

## 주요 변수 (`roles/k8s_app/defaults/main.yml`)

| 변수 | 지금 | 메모 |
|---|---|---|
| `pretix_cpu_limit` | `"1"` | 0.5면 시작 중 WORKER TIMEOUT 반복 |
| `pretix_mem_limit` | `1536Mi` | 1Gi에서 OOMKilled |
| `nginx_service_type` | `LoadBalancer` | ClusterIP로 두면 80이 닫힌다 |
| `nginx_alb_backup` | `true` | 지금 입구는 온프렘. ALB 입구 전환 뒤 `false` |
| `nginx_max_conns` | `10` | 0이면 제한 없음 |
| `pretix_url` | `""` | 비우면 원본 url. ALB 입구 전환 때 ALB 주소 |
| `nginx_real_ip_from` | `[]` | ALB 뒤일 때 `[10.0.0.0/16, 10.42.0.0/16]` |

`pretix.cfg` 원본은 VM의 `/root/stack/pretix.cfg`다. 롤은 이걸 읽어 DB 주소(`host=db` → `10.10.0.2`)와 url만 바꿔 k3s Secret으로 넣는다. 원본 파일은 건드리지 않는다.

## VM에서 확인할 때

```bash
ssh test@10.10.0.2
sudo -i
kubectl get pods -n pretix
kubectl logs -n pretix deploy/nginx -c nginx --tail=20
```

## 규칙

- VM의 k3s 설정이나 Ansible이 만든 파일을 손으로 바꾸지 않는다. 다음 실행 때 되돌아간다. 급해서 바꿨다면 같은 값을 코드에도 넣는다.
- 바꾸기 전에 `--check --diff`로 본다.
- `main`에 직접 푸시하지 않고 PR로 올리며 한 명 이상이 본다.
- 비밀값(DB 비밀번호, AWS 키, vault 비밀번호, `.pem`)은 저장소에 올리지 않는다. 실수로 올리면 지우는 것으로 끝내지 말고 키를 폐기하고 새로 발급한다.
- 무엇이 자동이고 무엇이 수동인지는 `docs/automation-boundary.md`에 적는다.
