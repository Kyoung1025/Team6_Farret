output "asg_name" {
  description = "Auto Scaling 그룹 이름"
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.app.id
}

output "ecr_repository_url" {
  description = "pretix 이미지 저장소 주소"
  value       = aws_ecr_repository.pretix.repository_url
}
