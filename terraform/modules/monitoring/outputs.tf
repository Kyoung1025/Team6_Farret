output "sns_topic_arn" {
  description = "알림 SNS 토픽. 다른 알람도 여기로 보낸다"
  value       = aws_sns_topic.alerts.arn
}
