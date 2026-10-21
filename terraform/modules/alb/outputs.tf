output "dns_name" {
  description = "ALB DNS 이름"
  value       = aws_lb.app.dns_name
}

output "arn_suffix" {
  description = "CloudWatch 알람의 LoadBalancer 차원 값"
  value       = aws_lb.app.arn_suffix
}

output "target_group_arn" {
  description = "ASG가 서버를 등록할 대상 그룹"
  value       = aws_lb_target_group.app.arn
}

output "target_group_arn_suffix" {
  description = "CloudWatch 알람의 TargetGroup 차원 값"
  value       = aws_lb_target_group.app.arn_suffix
}

output "listener_arn" {
  description = "80 리스너 (failover Lambda가 가중치를 바꿈)"
  value       = aws_lb_listener.http.arn
}

output "onprem_target_group_arn" {
  description = "온프렘 대상 그룹"
  value       = aws_lb_target_group.onprem.arn
}

output "onprem_target_group_arn_suffix" {
  description = "CloudWatch 알람의 TargetGroup 차원 값 (온프렘)"
  value       = aws_lb_target_group.onprem.arn_suffix
}

output "waf_name" {
  description = "WAF 웹 ACL 이름"
  value       = aws_wafv2_web_acl.main.name
}
