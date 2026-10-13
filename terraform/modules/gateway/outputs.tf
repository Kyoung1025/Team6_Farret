output "wg_public_ip" {
  description = "WireGuard 탄력적 IP. 온프렘 wg0.conf의 Endpoint"
  value       = aws_eip.wg.public_ip
}

output "wg_private_ip" {
  description = "WireGuard 서버 사설 IP"
  value       = aws_instance.wg.private_ip
}

output "nat_instance_id" {
  description = "NAT 인스턴스 ID"
  value       = aws_instance.nat.id
}
