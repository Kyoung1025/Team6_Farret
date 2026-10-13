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
