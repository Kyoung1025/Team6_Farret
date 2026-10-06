# AWS 구축 가이드 3-3(보안그룹)을 코드로 옮긴 것
# 소스를 IP 대신 다른 보안그룹으로 지정해서 ALB → 앱 순서의 접근만 허용한다
# SSH(22)는 어디에도 열지 않는다. 인스턴스 접속은 SSM Session Manager로 한다

locals {
  app_subnet_cidrs = { for k, s in var.app_subnets : k => s.cidr }
}

# --- ALB: 인터넷에 열리는 유일한 웹 입구 ---

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "ALB: HTTP from internet"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

# --- 앱 EC2: ALB에서 오는 요청만 받는다 ---

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "App EC2: HTTP from ALB only"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-app-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "HTTP from ALB"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb.id
}

# --- NAT 인스턴스: 앱 서브넷의 바깥 트래픽을 받는다 ---

resource "aws_security_group" "nat" {
  name        = "${var.name_prefix}-nat-sg"
  description = "NAT instance: all traffic from app subnets"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-nat-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "nat_from_app" {
  for_each = local.app_subnet_cidrs

  security_group_id = aws_security_group.nat.id
  description       = "All traffic from app-${each.key}"
  ip_protocol       = "-1"
  cidr_ipv4         = each.value
}

# --- WireGuard 서버: 온프렘 터널 + 앱 서브넷의 DB 요청 ---

resource "aws_security_group" "wg" {
  name        = "${var.name_prefix}-wg-sg"
  description = "WireGuard: tunnel from on-prem, forward from app subnets"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-wg-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "wg_tunnel" {
  security_group_id = aws_security_group.wg.id
  description       = "WireGuard from on-prem"
  ip_protocol       = "udp"
  from_port         = 51820
  to_port           = 51820
  cidr_ipv4         = var.onprem_public_cidr
}

resource "aws_vpc_security_group_ingress_rule" "wg_from_app" {
  for_each = local.app_subnet_cidrs

  security_group_id = aws_security_group.wg.id
  description       = "All traffic from app-${each.key} (to tunnel)"
  ip_protocol       = "-1"
  cidr_ipv4         = each.value
}

# --- 아웃바운드: 4개 모두 전체 허용 (콘솔 기본값과 같게) ---
# Terraform으로 만든 보안그룹은 기본 아웃바운드 규칙이 없어서 직접 넣어야 한다

resource "aws_vpc_security_group_egress_rule" "all" {
  for_each = {
    alb = aws_security_group.alb.id
    app = aws_security_group.app.id
    nat = aws_security_group.nat.id
    wg  = aws_security_group.wg.id
  }

  security_group_id = each.value
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
