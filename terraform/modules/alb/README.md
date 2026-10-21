# alb

인터넷에서 받는 ALB, HTTP 리스너, 대상 그룹(AWS 앱, 온프렘), WAF를 만든다. (AWS 구축 가이드 7번)

리스너는 가중치로 AWS / 온프렘에 나눈다. 평소 100 : 0. 장애 때는 failover Lambda(`monitoring`)가 0 : 100으로 바꾸고 복귀는 사람이 한다. 그래서 리스너 `default_action`은 처음 만들 때만 Terraform 값을 쓰고 이후 변경은 무시한다.
AWS 앱 쪽은 서버마다 Redis가 따로라 리스너에서 대상 그룹 단위로 1시간 세션을 고정한다. 가중치를 바꿀 때 이 설정을 빼면 AWS가 거부한다.
WAF 관리형 규칙 2개는 지금 Count(기록만, 차단 안 함)로 되어 있다.

## 입력

| 이름 | 설명 |
|---|---|
| `name_prefix` | 리소스 이름 접두사 |
| `vpc_id` | 대상 그룹을 만들 VPC |
| `subnet_ids` | ALB를 둘 Public 서브넷 (AZ 2개 이상) |
| `security_group_id` | ALB 보안그룹 |
| `onprem_target_ip` | 온프렘 VM WireGuard 주소 (기본 10.10.0.2) |
| `weight_app`, `weight_onprem` | 처음 만들 때 가중치 (기본 100, 0) |

## 출력

| 이름 | 설명 |
|---|---|
| `dns_name` | ALB 주소 |
| `arn_suffix` | CloudWatch 알람의 LoadBalancer 차원 값 |
| `target_group_arn` | ASG가 서버를 등록할 대상 그룹 |
| `target_group_arn_suffix` | CloudWatch 알람의 TargetGroup 차원 값 |
| `listener_arn` | 80 리스너 (failover Lambda가 사용) |
| `onprem_target_group_arn`, `onprem_target_group_arn_suffix` | 온프렘 대상 그룹 |
| `waf_name` | WAF 웹 ACL 이름 (대시보드) |
