output "wg_public_ip" {
  description = "WireGuard 탄력적 IP"
  value       = aws_eip.wg.public_ip
}

output "wg_asg_name" {
  description = "WireGuard 허브 ASG"
  value       = aws_autoscaling_group.wg.name
}

output "nat_instance_id" {
  description = "NAT 인스턴스 ID"
  value       = aws_instance.nat.id
}
