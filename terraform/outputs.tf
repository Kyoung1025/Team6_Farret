output "alb_dns_name" {
  description = "ALB 주소. 온프렘 Nginx의 backup 서버로 넣는다"
  value       = module.alb.dns_name
}

output "asg_name" {
  description = "Auto Scaling 그룹 이름"
  value       = module.app.asg_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "wg_public_ip" {
  description = "WireGuard 탄력적 IP. 온프렘 wg0.conf의 Endpoint"
  value       = module.gateway.wg_public_ip
}
