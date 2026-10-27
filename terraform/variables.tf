variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project" {
  description = "Project 태그 값"
  type        = string
  default     = "pretix-demo"
}

variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
  default     = "pretix-demo"
}

# --- network ---

# 온프렘 LAN 대역과 겹치면 안 됨
variable "vpc_cidr" {
  description = "VPC 대역"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public 서브넷 (ALB, NAT, WireGuard)"
  type = map(object({
    az   = string
    cidr = string
  }))
  default = {
    a = { az = "ap-northeast-2a", cidr = "10.0.1.0/24" }
    c = { az = "ap-northeast-2c", cidr = "10.0.2.0/24" }
  }
}

variable "app_subnets" {
  description = "App 서브넷 (앱 EC2)"
  type = map(object({
    az   = string
    cidr = string
  }))
  default = {
    a = { az = "ap-northeast-2a", cidr = "10.0.11.0/24" }
    c = { az = "ap-northeast-2c", cidr = "10.0.12.0/24" }
  }
}

# 실제 값은 terraform.tfvars
variable "onprem_public_cidr" {
  description = "온프렘 공인 IP (/32). wg-sg의 UDP 51820 소스"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.onprem_public_cidr, 0))
    error_message = "CIDR 형식이어야 합니다. 예: 203.0.113.10/32"
  }
}

# --- app ---

variable "app_ami_id" {
  description = "앱 EC2 AMI (Ubuntu 24.04)"
  type        = string
  default     = "ami-0e4ab31f1847c850c"
}

variable "app_ami_snapshot_id" {
  description = "app_ami_id의 루트 볼륨 스냅샷"
  type        = string
  default     = "snap-02f31e91c80bcad76"
}

# 온프렘 공인 IP가 들어가서 terraform.tfvars에 뒀음
variable "pretix_public_url" {
  description = "pretix.cfg의 url (온프렘과 같은 값)"
  type        = string
}

# 시작 템플릿 v8에 들어간 값. 쓰려면 terraform.tfvars에 넣는다
variable "pretix_django_secret" {
  description = "pretix.cfg [django] secret (비우면 섹션 없음)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pretix_mail_user" {
  description = "pretix 메일 발신 계정. 비밀번호는 Secrets Manager pretix/smtp-password"
  type        = string
  default     = "up041601@gmail.com"
}

# --- gateway ---

variable "nat_ami_id" {
  description = "NAT 인스턴스 AMI (Amazon Linux 2023)"
  type        = string
  default     = "ami-0870825cefcaafcc8"
}

variable "wg_ami_id" {
  description = "WireGuard 허브 AMI (WireGuard, AWS CLI 포함)"
  type        = string
  default     = "ami-0eb023a7877e74a71"
}

variable "onprem_tunnel_cidr" {
  description = "WireGuard 터널 대역"
  type        = string
  default     = "10.10.0.0/24"
}

# --- monitoring (terraform.tfvars) ---

variable "alert_email" {
  description = "알림 받을 이메일"
  type        = string
}

variable "discord_webhook_url" {
  description = "디스코드 웹훅 URL"
  type        = string
  sensitive   = true
}

# --- scheduled scaling ---

variable "enable_scheduled_scaling" {
  description = "원서 마감 예약 스케일링 사용 여부"
  type        = bool
  default     = false
}

# 기본값: 10/29 17:15 예열, 17:30 피크, 18:10 원복
variable "scaling_schedules" {
  description = "예약 스케일링 (cron: 분 시 일 월 요일)"
  type = map(object({
    recurrence       = string
    min_size         = number
    max_size         = number
    desired_capacity = number
  }))
  default = {
    prewarm = { recurrence = "15 17 29 10 *", min_size = 1, max_size = 4, desired_capacity = 2 }
    peak    = { recurrence = "30 17 29 10 *", min_size = 2, max_size = 4, desired_capacity = 4 }
    restore = { recurrence = "10 18 29 10 *", min_size = 0, max_size = 4, desired_capacity = 0 }
  }
}

# 평소 AWS 100, 온프렘 0. 처음 만들 때만 쓰고, 이후 가중치는 failover Lambda와 사람이 바꾼다
variable "alb_weight_app" {
  description = "ALB 리스너 가중치: AWS 앱"
  type        = number
  default     = 100
}

variable "alb_weight_onprem" {
  description = "ALB 리스너 가중치: 온프렘"
  type        = number
  default     = 0
}

# 지운 보관함은 이 기간 동안 같은 이름으로 다시 못 만든다. 테스트 계정에서 destroy/apply를 반복할 때만 0
variable "secret_recovery_window_days" {
  description = "Secrets Manager 보관함 복구 대기 일수"
  type        = number
  default     = 30
}
