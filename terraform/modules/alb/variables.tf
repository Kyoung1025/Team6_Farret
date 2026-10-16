variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "vpc_id" {
  description = "대상 그룹을 만들 VPC"
  type        = string
}

variable "subnet_ids" {
  description = "ALB를 둘 Public 서브넷 (AZ 2개 이상)"
  type        = list(string)
}

variable "security_group_id" {
  description = "ALB 보안그룹"
  type        = string
}

variable "onprem_target_ip" {
  description = "온프렘 VM의 WireGuard 주소"
  type        = string
  default     = "10.10.0.2"
}

variable "weight_app" {
  description = "리스너 가중치: AWS 앱"
  type        = number
  default     = 100
}

variable "weight_onprem" {
  description = "리스너 가중치: 온프렘. 장애 때 올린다"
  type        = number
  default     = 0
}
