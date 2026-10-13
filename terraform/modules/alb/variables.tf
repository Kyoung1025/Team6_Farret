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
