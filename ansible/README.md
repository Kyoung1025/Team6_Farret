# 저장소 구조와 규칙

하나의 저장소에 두 도구를 함께 둔다. 이름은 예시다.

```
pretix-infra/
├─ ansible/
│  ├─ ansible.cfg
│  ├─ requirements.yml            # ansible.posix 등 collection
│  ├─ inventory/hosts.yml
│  ├─ group_vars/all/vars.yml     # 비밀 아닌 값
│  ├─ group_vars/all/vault.yml    # ansible-vault로 암호화
│  ├─ site.yml
│  └─ roles/{common,docker,wireguard,firewalld,db_stack,k3s,k8s_app,exporters,backup}/
├─ terraform/
│  ├─ bootstrap/                  # state 버킷 (처음 한 번)
│  ├─ persistent/                 # EIP, ECR, 시크릿 같은 지우지 않는 것
│  ├─ envs/demo/                  # main.tf, variables.tf, outputs.tf, backend.tf
│  └─ modules/{network,edge,iam,compute,alb,waf,observability,backup}/
├─ docs/automation-boundary.md
└─ .github/workflows/ci.yml
```

## 규칙

- `main`에 직접 푸시하지 않고 PR로 올리며 한 명 이상이 본다.
- 비밀값(DB 비밀번호, AWS 키, vault 비밀번호, `.pem`)은 저장소에 올리지 않는다. 실수로 올리면 지우는 것으로 끝내지 말고 키를 폐기하고 새로 발급한다.
- Terraform 코드를 고칠 때는 저장 전에 `terraform fmt`를 돌린다.
- AWS 콘솔에서 직접 고치지 않는다.
- `docs/automation-boundary.md`는 팀이 함께 유지한다.
