# AWS 구축 가이드 3-3(보안그룹)을 코드로 옮긴 것
# 소스를 IP 대신 다른 보안그룹으로 지정해서 ALB → 앱 순서의 접근만 허용한다
# SSH(22)는 어디에도 열지 않는다. 인스턴스 접속은 SSM Session Manager로 한다
#
# 보안그룹 description은 바꾸면 보안그룹을 지우고 다시 만들어야 해서, 설명은 주석으로 적음.

locals {
  app_subnet_cidrs = { for k, s in var.app_subnets : k => s.cidr }
}

# --- ALB: 인터넷에 열리는 유일한 웹 입구 ---

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

# --- 앱 EC2: ALB에서 오는 요청만 받는다 ---

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

# --- NAT 인스턴스: 앱 서브넷의 바깥 트래픽을 받는다 ---

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

# --- WireGuard 서버: 온프렘 터널 + 앱 서브넷의 DB 요청 ---

resource "aws_security_group" "wg" {
  name        = "${var.name_prefix}-wg-sg"
  description = "${var.name_prefix}-wg-sg"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-wg-sg" }
}

# WireGuard from on-prem
resource "aws_vpc_security_group_ingress_rule" "wg_tunnel" {
  security_group_id = aws_security_group.wg.id
  description       = " on-prem WireGuard (sungho public IP)" # 콘솔 값과 같게 (앞 공백 포함)
  ip_protocol       = "udp"
  from_port         = 51820
  to_port           = 51820
  cidr_ipv4         = var.onprem_public_cidr
}

# All traffic from app subnets (DB 요청을 터널로 넘긴다)
resource "aws_vpc_security_group_ingress_rule" "wg_from_app" {
  for_each = local.app_subnet_cidrs

  security_group_id = aws_security_group.wg.id
  description       = "app-${each.key} to on-prem DB via tunnel"
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
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
