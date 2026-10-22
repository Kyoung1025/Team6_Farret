# iam

여러 모듈이 쓰는 IAM 역할 3개를 만든다. 원래 콘솔에서 만들고 다른 모듈은 이름만 가져다 썼는데, 그러면 다른 계정에 처음부터 만들 때 역할이 없어서 실패해서 코드로 옮겼다.

| 역할 | 쓰는 곳 | 권한 |
|---|---|---|
| `<name_prefix>-app-role` (+ 인스턴스 프로파일) | 앱 서버 시작 템플릿 | ECR 읽기, SSM, Secrets Manager의 `pretix/db-password`, `pretix/smtp-password` 읽기 |
| `<name_prefix>-infra-role` (+ 인스턴스 프로파일) | NAT 인스턴스 | SSM (Session Manager 접속) |
| `<name_prefix>-lambda-alert-role` | 디스코드 알림 Lambda | CloudWatch Logs 쓰기 |

허브 역할은 `gateway`, 자동 전환 Lambda 역할은 `monitoring` 안에 있다. 그 역할을 쓰는 곳이 한 모듈뿐이라서.

앱 역할의 `AmazonSSMFullAccess`는 콘솔에서 붙여 둔 그대로 옮겼다. Session Manager 접속만 쓰면 `AmazonSSMManagedInstanceCore`로 충분해서 나중에 뺄 예정.

## 입력

| 이름 | 설명 |
|---|---|
| `name_prefix` | 리소스 이름 접두사 |
| `region` | 비밀번호 읽기 권한의 리전 |

## 출력

| 이름 | 설명 |
|---|---|
| `app_instance_profile_arn` | 앱 서버 인스턴스 프로파일 |
| `infra_instance_profile_name` | NAT 인스턴스 프로파일 |
| `lambda_alert_role_arn` | 디스코드 Lambda 역할 |
