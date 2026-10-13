# alb

인터넷에서 받는 ALB, HTTP 리스너, 대상 그룹을 만든다. (AWS 구축 가이드 7번)

## 입력

| 이름 | 설명 |
|---|---|
| `name_prefix` | 리소스 이름 접두사 |
| `vpc_id` | 대상 그룹을 만들 VPC |
| `subnet_ids` | ALB를 둘 Public 서브넷 (AZ 2개 이상) |
| `security_group_id` | ALB 보안그룹 |

## 출력

| 이름 | 설명 |
|---|---|
| `dns_name` | ALB 주소 (온프렘 Nginx backup 서버) |
| `arn_suffix` | CloudWatch 알람의 LoadBalancer 차원 값 |
| `target_group_arn` | ASG가 서버를 등록할 대상 그룹 |
| `target_group_arn_suffix` | CloudWatch 알람의 TargetGroup 차원 값 |
