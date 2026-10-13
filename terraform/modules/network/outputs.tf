output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public 서브넷 ID 목록 (ALB가 사용)"
  value       = [for s in aws_subnet.public : s.id]
}

output "app_subnet_ids" {
  description = "App 서브넷 ID 목록 (ASG가 사용)"
  value       = [for s in aws_subnet.app : s.id]
}

output "app_route_table_id" {
  description = "App 라우팅 테이블 ID (NAT·WireGuard 경로를 추가할 곳)"
  value       = aws_route_table.app.id
}

output "security_group_ids" {
  description = "보안그룹 ID (alb, app, nat, wg)"
  value = {
    alb = aws_security_group.alb.id
    app = aws_security_group.app.id
    nat = aws_security_group.nat.id
    wg  = aws_security_group.wg.id
  }
}
