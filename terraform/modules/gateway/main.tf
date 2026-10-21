# source_dest_check를 꺼야 다른 서버 트래픽을 넘길 수 있음

data "aws_caller_identity" "current" {}

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

resource "aws_route" "app_internet" {
  route_table_id         = var.app_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat.primary_network_interface_id
}

# --- WireGuard 허브 ---
# ASG 1대. 죽으면 새 인스턴스가 떠서 부팅 스크립트가
# 키 읽기 → wg0 시작 → EIP 가져오기 → 10.10.0.0/24 경로를 자기로 바꾸기 를 한다.
# 그래서 EIP 연결과 터널 경로는 Terraform이 아니라 인스턴스가 관리한다.
# 개인키와 wg0.conf 본문은 SSM 파라미터(/pretix/wg/*)에 사람이 넣는다

resource "aws_eip" "wg" {
  domain = "vpc"

  tags = { Name = "wireguard-instance-ip" }
}

resource "aws_iam_role" "wg" {
  name        = "${var.name_prefix}-wg-role"
  description = "Allows EC2 instances to call AWS services on your behalf."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "wg_hub" {
  name = "${var.name_prefix}-wg-hub-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/pretix/wg/*"
      },
      {
        Effect = "Allow"
        Action = ["ec2:ModifyInstanceAttribute", "ec2:AssociateAddress"]
        Resource = [
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:elastic-ip/${aws_eip.wg.id}",
        ]
      },
      {
        Effect = "Allow"
        Action = ["ec2:ReplaceRoute", "ec2:CreateRoute"]
        Resource = [
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:route-table/${var.app_route_table_id}",
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:route-table/${var.public_route_table_id}",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "wg_hub" {
  role       = aws_iam_role.wg.name
  policy_arn = aws_iam_policy.wg_hub.arn
}

resource "aws_iam_role_policy_attachment" "wg_ssm" {
  role       = aws_iam_role.wg.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "wg" {
  name = aws_iam_role.wg.name
  role = aws_iam_role.wg.name
}

resource "aws_launch_template" "wg" {
  name          = "${var.name_prefix}-wg-lt"
  image_id      = var.wg_ami_id
  instance_type = "t3.micro"

  iam_instance_profile {
    arn = aws_iam_instance_profile.wg.arn
  }

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    security_groups             = [var.wg_security_group_id]
  }

  metadata_options {
    http_tokens = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Project = var.name_prefix
      Name    = "${var.name_prefix}-wg"
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/wg-hub-user-data.sh.tftpl", {
    region             = var.region
    eip_allocation_id  = aws_eip.wg.id
    app_route_table_id = var.app_route_table_id
    pub_route_table_id = var.public_route_table_id
    onprem_tunnel_cidr = var.onprem_tunnel_cidr
  }))
}

resource "aws_autoscaling_group" "wg" {
  name                      = "${var.name_prefix}-wg-asg"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = var.public_subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.wg.id
    version = "$Default"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-wg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.name_prefix
    propagate_at_launch = true
  }
}
