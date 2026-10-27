output "app_instance_profile_arn" {
  description = "앱 서버 시작 템플릿에 붙일 인스턴스 프로파일"
  value       = aws_iam_instance_profile.app.arn
}

output "infra_instance_profile_name" {
  description = "NAT 인스턴스에 붙일 인스턴스 프로파일"
  value       = aws_iam_instance_profile.infra.name
}

output "lambda_alert_role_arn" {
  description = "디스코드 알림 Lambda 실행 역할"
  value       = aws_iam_role.lambda_alert.arn
}
