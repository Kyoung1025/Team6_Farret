output "sns_topic_arn" {
  description = "알림 SNS 토픽 ARN"
  value       = aws_sns_topic.alerts.arn
}
