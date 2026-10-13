variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "region" {
  description = "대시보드 위젯의 리전"
  type        = string
}

variable "asg_name" {
  description = "CPU 알람을 걸 Auto Scaling 그룹"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB 지표의 LoadBalancer 차원 값"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ALB 지표의 TargetGroup 차원 값"
  type        = string
}

variable "alert_email" {
  description = "알림을 받을 이메일"
  type        = string
}

variable "discord_webhook_url" {
  description = "디스코드 웹훅 URL"
  type        = string
  sensitive   = true
}

variable "lambda_role_arn" {
  description = "Lambda 실행 역할 ARN"
  type        = string
}

variable "lambda_source_file" {
  description = "Lambda 코드 파일 경로"
  type        = string
}
