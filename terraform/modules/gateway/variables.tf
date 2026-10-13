variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "subnet_id" {
  description = "NAT·WireGuard를 둘 Public 서브넷"
  type        = string
}

variable "nat_ami_id" {
  description = "NAT 인스턴스 AMI (Amazon Linux 2023)"
  type        = string
}

variable "wg_ami_id" {
  description = "WireGuard 서버 AMI (Ubuntu 24.04)"
  type        = string
}

variable "nat_security_group_id" {
  description = "NAT 보안그룹"
  type        = string
}

variable "wg_security_group_id" {
  description = "WireGuard 보안그룹"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM 인스턴스 프로파일 이름"
  type        = string
}

variable "app_route_table_id" {
  description = "경로를 추가할 App 라우팅 테이블"
  type        = string
}

variable "onprem_tunnel_cidr" {
  description = "WireGuard 터널 대역"
  type        = string
}
