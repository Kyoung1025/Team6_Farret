variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "region" {
  description = "Secrets Manager 리전 (비밀번호 읽기 권한 범위)"
  type        = string
}
