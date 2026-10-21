variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "region" {
  description = "대시보드 위젯의 리전"
  type        = string
}

variable "asg_name" {
  description = "대시보드 7, 8번 패널의 Auto Scaling 그룹"
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

variable "log_retention_days" {
  description = "Lambda 로그 보관 기간 (일)"
  type        = number
  default     = 14
}

# --- 자동 전환, 대시보드 ---

variable "listener_arn" {
  description = "failover Lambda가 가중치를 바꿀 ALB 리스너"
  type        = string
}

variable "target_group_arn" {
  description = "AWS 앱 대상 그룹"
  type        = string
}

variable "onprem_target_group_arn" {
  description = "온프렘 대상 그룹"
  type        = string
}

variable "onprem_target_group_arn_suffix" {
  description = "대시보드 2번 패널의 TargetGroup 차원 값"
  type        = string
}

variable "waf_name" {
  description = "대시보드 10번 패널의 WebACL 이름"
  type        = string
}

variable "failover_source_file" {
  description = "failover Lambda 코드 파일 경로"
  type        = string
}
