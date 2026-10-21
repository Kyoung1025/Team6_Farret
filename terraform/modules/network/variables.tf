variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "region" {
  description = "S3 엔드포인트 서비스 이름에 쓰는 리전"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC 대역"
  type        = string
}

variable "public_subnets" {
  description = "Public 서브넷 (ALB, NAT, WireGuard)"
  type = map(object({
    az   = string
    cidr = string
  }))
}

variable "app_subnets" {
  description = "App 서브넷 (앱 EC2)"
  type = map(object({
    az   = string
    cidr = string
  }))
}

variable "onprem_public_cidr" {
  description = "온프렘 공인 IP (/32). wg-sg의 UDP 51820 소스"
  type        = string
}
