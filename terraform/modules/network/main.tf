# AWS 구축 가이드 3번(네트워크)을 코드로 옮긴 것

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = false # 콘솔 구성과 같게. 인터페이스 엔드포인트를 쓰게 되면 true로 바꾼다

  tags = { Name = "${var.name_prefix}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-igw" }
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true # NAT·WireGuard 인스턴스가 퍼블릭 IP를 받는다

  tags = { Name = "${var.name_prefix}-public-${each.key}" }
}

# 앱 EC2는 퍼블릭 IP를 받지 않는다 (NAT로만 나간다)
resource "aws_subnet" "app" {
  for_each = var.app_subnets

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = false

  tags = { Name = "${var.name_prefix}-app-${each.key}" }
}

# --- 라우팅 ---

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# 0.0.0.0/0 → NAT, 10.10.0.0/24 → WireGuard 경로는
# 두 인스턴스를 코드로 옮길 때(nat_wg.tf) aws_route 리소스로 추가한다
resource "aws_route_table" "app" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-rt-app" }
}

resource "aws_route_table_association" "app" {
  for_each = aws_subnet.app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.app.id
}

# S3 게이트웨이 엔드포인트: 무료, S3 접근이 NAT를 거치지 않는다
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.app.id]

  tags = { Name = "${var.name_prefix}-s3-ep" }
}
