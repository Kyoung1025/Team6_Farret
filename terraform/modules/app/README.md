# app

앱 EC2의 Launch Template, Auto Scaling 그룹, 확장 정책을 만든다. (AWS 구축 가이드 6번)

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
| `allowed_hosts` | pretix가 받아들이는 Host 목록 |

## 출력

| 이름 | 설명 |
|---|---|
| `asg_name` | Auto Scaling 그룹 이름 |
| `launch_template_id` | Launch Template ID |
