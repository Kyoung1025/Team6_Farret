variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "region" {
  description = "ECR, Secrets Manager 리전"
  type        = string
}

variable "instance_profile_arn" {
  description = "앱 서버 인스턴스 프로파일 (iam 모듈)"
  type        = string
}

variable "ami_id" {
  description = "앱 EC2 AMI (Ubuntu 24.04, 서울)"
  type        = string
}

variable "ami_snapshot_id" {
  description = "ami_id의 루트 볼륨 스냅샷"
  type        = string
}

variable "subnet_ids" {
  description = "앱 EC2를 띄울 App 서브넷"
  type        = list(string)
}

variable "security_group_id" {
  description = "앱 EC2 보안그룹"
  type        = string
}

variable "target_group_arn" {
  description = "ASG가 서버를 등록할 ALB 대상 그룹"
  type        = string
}

variable "public_url" {
  description = "pretix.cfg의 url"
  type        = string
}

variable "django_secret" {
  description = "pretix.cfg [django] secret. 서버끼리 같아야 로그인이 유지된다. 비우면 섹션을 안 넣음"
  type        = string
  default     = ""
  sensitive   = true
}

variable "mail_user" {
  description = "pretix 메일 발신 계정 (Gmail SMTP)"
  type        = string
}

variable "enable_scheduled_scaling" {
  description = "예약 스케일링 사용 여부"
  type        = bool
  default     = false
}

variable "scaling_schedules" {
  description = "예약 스케일링 (recurrence는 cron, Asia/Seoul 기준)"
  type = map(object({
    recurrence       = string
    min_size         = number
    max_size         = number
    desired_capacity = number
  }))
  default = {}
}
