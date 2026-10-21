variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "region" {
  description = "리전 (WireGuard 허브 부팅 스크립트, IAM 정책)"
  type        = string
}

variable "subnet_id" {
  description = "NAT를 둘 Public 서브넷"
  type        = string
}

variable "public_subnet_ids" {
  description = "WireGuard 허브 ASG가 쓸 Public 서브넷"
  type        = list(string)
}

variable "nat_ami_id" {
  description = "NAT 인스턴스 AMI (Amazon Linux 2023)"
  type        = string
}

variable "wg_ami_id" {
  description = "WireGuard 허브 AMI (WireGuard, AWS CLI가 깔린 이미지)"
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
  description = "NAT 인스턴스의 IAM 인스턴스 프로파일"
  type        = string
}

variable "app_route_table_id" {
  description = "App 라우팅 테이블 (NAT 경로, 터널 경로)"
  type        = string
}

variable "public_route_table_id" {
  description = "Public 라우팅 테이블 (터널 경로. ALB → 온프렘 대상 그룹)"
  type        = string
}

variable "onprem_tunnel_cidr" {
  description = "WireGuard 터널 대역"
  type        = string
}
