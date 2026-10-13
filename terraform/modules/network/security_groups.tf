# SSH는 열지 않음 (SSM으로 접속)
# SG description은 바꾸면 재생성되므로 콘솔 값 유지

locals {
  app_subnet_cidrs = { for k, s in var.app_subnets : k => s.cidr }
}

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "${var.name_prefix}-alb-sg"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-alb-sg" }
}

# HTTP from internet
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "${var.name_prefix}-app-sg"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-app-sg" }
}

# HTTP from ALB
resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  security_group_id            = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "nat" {
  name        = "${var.name_prefix}-nat-sg"
  description = "${var.name_prefix}-nat-sg"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-nat-sg" }
}

# All traffic from app subnets
resource "aws_vpc_security_group_ingress_rule" "nat_from_app" {
  for_each = local.app_subnet_cidrs

  security_group_id = aws_security_group.nat.id
  ip_protocol       = "-1"
  cidr_ipv4         = each.value
}

resource "aws_security_group" "wg" {
  name        = "${var.name_prefix}-wg-sg"
  description = "${var.name_prefix}-wg-sg"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-wg-sg" }
}

# WireGuard from on-prem
resource "aws_vpc_security_group_ingress_rule" "wg_tunnel" {
  security_group_id = aws_security_group.wg.id
  description       = "on-prem WireGuard"
  ip_protocol       = "udp"
  from_port         = 51820
  to_port           = 51820
  cidr_ipv4         = var.onprem_public_cidr
}

# All traffic from app subnets
resource "aws_vpc_security_group_ingress_rule" "wg_from_app" {
  for_each = local.app_subnet_cidrs

  security_group_id = aws_security_group.wg.id
  description       = "app-${each.key} to on-prem DB via tunnel"
  ip_protocol       = "-1"
  cidr_ipv4         = each.value
}

# Terraform은 기본 egress 규칙을 만들지 않아서 직접 추가

resource "aws_vpc_security_group_egress_rule" "all" {
  for_each = {
    alb = aws_security_group.alb.id
    app = aws_security_group.app.id
    nat = aws_security_group.nat.id
    wg  = aws_security_group.wg.id
  }

  security_group_id = each.value
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
