variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "region" {
  description = "ECR, Secrets Manager 리전"
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

variable "allowed_hosts" {
  description = "pretix.cfg의 hosts"
  type        = string
}
