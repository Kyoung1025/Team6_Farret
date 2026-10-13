variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "region" {
  description = "부팅 스크립트가 ECR·Secrets Manager를 부를 리전"
  type        = string
}

variable "ami_id" {
  description = "앱 EC2 AMI (Ubuntu 24.04, 서울)"
  type        = string
}

variable "ami_snapshot_id" {
  description = "ami_id의 루트 볼륨 스냅샷. AMI를 바꾸면 같이 바꾼다"
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
  description = "수험생이 접속하는 주소. 온프렘 pretix.cfg의 url과 같아야 한다"
  type        = string
}

variable "allowed_hosts" {
  description = "pretix가 받아들이는 Host 목록 (ALB 헬스 체크가 쓰는 사설 IP 대역 포함)"
  type        = string
}
