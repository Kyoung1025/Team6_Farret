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

# --- 앱 EC2 (app.tf) ---

variable "app_ami_id" {
  description = "앱 EC2 AMI (Ubuntu 24.04, 서울)"
  type        = string
  default     = "ami-0e4ab31f1847c850c"
}

variable "app_ami_snapshot_id" {
  description = "app_ami_id의 루트 볼륨 스냅샷. AMI를 바꾸면 같이 바꾼다"
  type        = string
  default     = "snap-02f31e91c80bcad76"
}

# 아래 두 값에는 온프렘 공인 IP가 들어가서 terraform.tfvars(커밋 안 됨)에 둔다
# 예: pretix_public_url    = "http://203.0.113.10"
#     pretix_allowed_hosts = "203.0.113.10,10.0.*,localhost,127.0.0.1"
variable "pretix_public_url" {
  description = "수험생이 접속하는 주소. 온프렘 pretix.cfg의 url과 같아야 한다"
  type        = string
}

variable "pretix_allowed_hosts" {
  description = "pretix가 받아들이는 Host 목록 (ALB 헬스 체크가 쓰는 사설 IP 대역 포함)"
  type        = string
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
