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

# 온프렘 공인 IP가 들어가서 terraform.tfvars에 둔다
variable "pretix_public_url" {
  description = "pretix.cfg의 url (온프렘과 같은 값)"
  type        = string
}

variable "pretix_allowed_hosts" {
  description = "pretix.cfg의 hosts (ALB 헬스 체크용 사설 대역 포함)"
  type        = string
}

# --- gateway ---

variable "nat_ami_id" {
  description = "NAT 인스턴스 AMI (Amazon Linux 2023)"
  type        = string
  default     = "ami-0870825cefcaafcc8"
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
