# AWS 구축 가이드 4번(NAT 인스턴스)과 5번(WireGuard 서버)을 코드로 옮긴 것
# 둘 다 다른 서버의 트래픽을 대신 넘겨 주므로 출발지/목적지 확인(source_dest_check)을 끈다

# --- NAT 인스턴스: 앱 서브넷의 인터넷 요청(ECR, 패키지 설치)을 내보낸다 ---

resource "aws_instance" "nat" {
  ami                    = var.nat_ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.nat_security_group_id]
  iam_instance_profile   = var.instance_profile_name
  source_dest_check      = false

  # iptables로 앱 서브넷 트래픽을 자기 공인 IP로 바꿔서(MASQUERADE) 내보낸다
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

# --- WireGuard 서버: 온프렘과 터널을 맺고 앱 EC2의 DB·Redis 요청을 넘긴다 ---
# WireGuard 설정(키 포함)은 서버 안에 직접 했고 user data가 없다. 키는 코드에 넣지 않는다

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

  tags = { Name = "wireguard-instance" } # 콘솔에서 지은 이름 그대로
}

# 온프렘 WireGuard가 접속할 주소라서 바뀌지 않는 탄력적 IP를 붙인다
resource "aws_eip" "wg" {
  domain = "vpc"

  tags = { Name = "wireguard-instance-ip" }
}

resource "aws_eip_association" "wg" {
  allocation_id = aws_eip.wg.id
  instance_id   = aws_instance.wg.id
}

# --- App 라우팅 테이블 경로 ---

# 인터넷으로 나가는 요청 → NAT 인스턴스
resource "aws_route" "app_internet" {
  route_table_id         = var.app_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat.primary_network_interface_id
}

# 온프렘 WireGuard 대역(DB 10.10.0.2) → WireGuard 서버
resource "aws_route" "app_onprem" {
  route_table_id         = var.app_route_table_id
  destination_cidr_block = var.onprem_tunnel_cidr
  network_interface_id   = aws_instance.wg.primary_network_interface_id
}
