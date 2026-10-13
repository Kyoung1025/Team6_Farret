# monitoring

알림과 대시보드를 만든다. 설계는 `monitoring/design.md`, Lambda 코드는 `monitoring/discord-notifier/`에 있다.

CloudWatch 알람 → SNS 토픽 `<name_prefix>-alerts` → 이메일 + Lambda → 디스코드

| 알람 | 조건 |
|---|---|
| `cpu-high` | ASG 평균 CPU 80% 초과 5분 |
| `latency-high` | 응답 시간 p95 2초 초과 3분 |
| `unhealthy-host` | 비정상 서버 1대 이상 2분 |

## 입력

| 이름 | 설명 |
|---|---|
| `name_prefix` | 리소스 이름 접두사 |
| `region` | 대시보드 위젯의 리전 |
| `asg_name` | CPU 알람을 걸 Auto Scaling 그룹 |
| `alb_arn_suffix` | ALB 지표의 LoadBalancer 차원 값 |
| `target_group_arn_suffix` | ALB 지표의 TargetGroup 차원 값 |
| `alert_email` | 알림을 받을 이메일 |
| `discord_webhook_url` | 디스코드 웹훅 URL (sensitive) |
| `lambda_role_arn` | Lambda 실행 역할 |
| `lambda_source_file` | Lambda 코드 파일 경로 |

## 출력

| 이름 | 설명 |
|---|---|
| `sns_topic_arn` | 알림 SNS 토픽 |
