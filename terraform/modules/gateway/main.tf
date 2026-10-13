# source_dest_check를 꺼야 다른 서버 트래픽을 넘길 수 있음

resource "aws_instance" "nat" {
  ami                    = var.nat_ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.nat_security_group_id]
  iam_instance_profile   = var.instance_profile_name
  source_dest_check      = false

  user_data = file("${path.module}/templates/nat-user-data.sh")

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = { Name = "${var.name_prefix}-nat" }
}

# WireGuard 설정과 키는 서버에서 직접 관리

resource "aws_instance" "wg" {
  ami                    = var.wg_ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.wg_security_group_id]
  iam_instance_profile   = var.instance_profile_name
  source_dest_check      = false

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = { Name = "wireguard-instance" }
}

resource "aws_eip" "wg" {
  domain = "vpc"

  tags = { Name = "wireguard-instance-ip" }
}

resource "aws_eip_association" "wg" {
  allocation_id = aws_eip.wg.id
  instance_id   = aws_instance.wg.id
}

resource "aws_route" "app_internet" {
  route_table_id         = var.app_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat.primary_network_interface_id
}

resource "aws_route" "app_onprem" {
  route_table_id         = var.app_route_table_id
  destination_cidr_block = var.onprem_tunnel_cidr
  network_interface_id   = aws_instance.wg.primary_network_interface_id
}
