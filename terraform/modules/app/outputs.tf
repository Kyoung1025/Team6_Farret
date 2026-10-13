output "asg_name" {
  description = "Auto Scaling 그룹 이름 (알람, 예약 스케일링에서 사용)"
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.app.id
}
