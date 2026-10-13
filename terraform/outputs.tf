output "alb_dns_name" {
  description = "ALB DNS 이름"
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
  description = "WireGuard 탄력적 IP"
  value       = module.gateway.wg_public_ip
}
