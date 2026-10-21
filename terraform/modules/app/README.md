# app

앱 EC2의 Launch Template, Auto Scaling 그룹, 확장 정책과
pretix 이미지 저장소(ECR), DB·SMTP 비밀번호 보관함(Secrets Manager)을 만든다. (AWS 구축 가이드 6번)
비밀번호 값은 콘솔에서 넣고 코드로 관리하지 않는다.

부팅 스크립트는 `templates/user-data.sh.tftpl`이고 `templatefile()`로 값을 채운다.
셸 변수 `${...}`는 Terraform 변수와 겹치지 않게 `$${...}`로 적는다.

## 입력

| 이름 | 설명 |
|---|---|
| `name_prefix` | 리소스 이름 접두사 |
| `region` | 부팅 스크립트가 ECR·Secrets Manager를 부를 리전 |
| `ami_id` | 앱 EC2 AMI |
| `ami_snapshot_id` | AMI의 루트 볼륨 스냅샷 |
| `subnet_ids` | 앱 EC2를 띄울 App 서브넷 |
| `security_group_id` | 앱 EC2 보안그룹 |
| `target_group_arn` | ALB 대상 그룹 |
| `public_url` | 수험생이 접속하는 주소 (pretix.cfg `url`) |
| `mail_user` | 메일 발신 Gmail 계정 (비밀번호는 Secrets Manager `pretix/smtp-password`) |
| `django_secret` | pretix.cfg `[django] secret`. 비우면 섹션을 안 넣는다 (sensitive) |

## 출력

| 이름 | 설명 |
|---|---|
| `asg_name` | Auto Scaling 그룹 이름 |
| `launch_template_id` | Launch Template ID |
| `ecr_repository_url` | pretix 이미지 저장소 주소 |

## 메모

- ASG는 시작 템플릿 `$Default` 버전을 쓴다. Terraform은 새 버전을 만들기만 하고 기본 버전은 바꾸지 않는다. 바꾼 뒤에는 콘솔이나 CLI로 기본 버전을 올리고 인스턴스 새로 고침을 한다.
- 부팅 스크립트의 nginx는 `/healthcheck/`에 바로 200을 준다. ALB 헬스 체크는 nginx가 살아 있는지만 본다.
