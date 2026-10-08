variable "region" {
  description = "AWS 리전 (서울)"
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

# 온프렘 LAN 대역이 10.0.x.x이면 겹치므로 바꿔야 함
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

# 지금은 콘솔 구성과 같은 0.0.0.0/0 (WireGuard는 키로 인증하므로 차선책)
# 온프렘 공인 IP가 정해지면 terraform.tfvars(커밋 안 됨)에 적어 덮어쓴다
# 예: onprem_public_cidr = "203.0.113.10/32"
variable "onprem_public_cidr" {
  description = "온프렘 공인 IP (/32). wg-sg의 UDP 51820 소스"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.onprem_public_cidr, 0))
    error_message = "CIDR 형식이어야 합니다. 예: 203.0.113.10/32"
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
