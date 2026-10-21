output "sns_topic_arn" {
  description = "알림 SNS 토픽 ARN"
  value       = aws_sns_topic.alerts.arn
}

output "failover_function_name" {
  description = "자동 전환 Lambda"
  value       = aws_lambda_function.failover.function_name
}
