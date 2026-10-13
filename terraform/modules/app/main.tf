# AWS 구축 가이드 6번(앱 EC2: Launch Template과 ASG)을 코드로 옮긴 것
# 콘솔 구성과 같게 맞춰 두었다. 설계 개선(AUTOMIGRATE=skip, pretix 버전 고정 등)은 별도 PR로 한다

data "aws_caller_identity" "current" {}

# --- Launch Template ---

resource "aws_launch_template" "app" {
  name          = "${var.name_prefix}-lt"
  image_id      = var.ami_id
  instance_type = "t3.medium"

  iam_instance_profile {
    arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.name_prefix}-app-role"
  }

  vpc_security_group_ids = [var.security_group_id]

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = "false"
      snapshot_id           = var.ami_snapshot_id # AMI의 루트 스냅샷 (콘솔이 자동으로 넣은 값)
    }
  }

  # IMDSv2 필수 (인스턴스 메타데이터를 토큰 없이 못 읽게)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # 부팅 스크립트: Docker 설치 → Secrets Manager에서 DB 비밀번호 조회 → pretix 실행
  user_data = base64encode(templatefile("${path.module}/templates/user-data.sh.tftpl", {
    region        = var.region
    account_id    = data.aws_caller_identity.current.account_id
    public_url    = var.public_url
    allowed_hosts = var.allowed_hosts
  }))
}

# --- Auto Scaling 그룹 ---

resource "aws_autoscaling_group" "app" {
  name                      = "${var.name_prefix}-asg"
  min_size                  = 0
  max_size                  = 4
  desired_capacity          = 0
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 600
  default_cooldown          = 300
  capacity_rebalance        = true # Spot 회수 경고가 오면 미리 대체 서버를 띄운다

  # On-Demand 1대를 기본으로 두고, 그 위로 늘어나는 서버는 전부 Spot
  mixed_instances_policy {
    instances_distribution {
      on_demand_allocation_strategy            = "prioritized"
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "price-capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.app.id
        version            = "$Default"
      }
      override {
        instance_type = "t3.medium"
      }
      override {
        instance_type = "t3a.medium"
      }
    }
  }

  # 대시보드의 서버 수 그래프용 그룹 지표
  metrics_granularity = "1Minute"
  enabled_metrics = [
    "GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity",
    "GroupInServiceInstances", "GroupInServiceCapacity",
    "GroupPendingInstances", "GroupPendingCapacity",
    "GroupStandbyInstances", "GroupStandbyCapacity",
    "GroupTerminatingInstances", "GroupTerminatingCapacity",
    "GroupTerminatingRetainedInstances", "GroupTerminatingRetainedCapacity",
    "GroupTotalInstances", "GroupTotalCapacity",
    "GroupAndWarmPoolDesiredCapacity", "GroupAndWarmPoolTotalCapacity",
    "WarmPoolDesiredCapacity", "WarmPoolMinSize", "WarmPoolTotalCapacity",
    "WarmPoolWarmedCapacity", "WarmPoolPendingCapacity", "WarmPoolPendingRetainedCapacity",
    "WarmPoolTerminatingCapacity", "WarmPoolTerminatingRetainedCapacity",
  ]

  # 서버 대수는 확장 정책과 예약 스케일링, 사람이 바꾼다. Terraform이 되돌리지 않게 제외
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# --- 확장 정책: 평균 CPU 60% 유지 (서버당 요청 수로 바꿀 예정) ---

resource "aws_autoscaling_policy" "cpu" {
  name                      = "Target Tracking Policy"
  autoscaling_group_name    = aws_autoscaling_group.app.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value     = 60
    disable_scale_in = false
  }
}

# --- 앱 서버가 쓰는 저장소 ---

# pretix 컨테이너 이미지 저장소. 부팅 스크립트가 여기서 pretix:stable을 받는다
resource "aws_ecr_repository" "pretix" {
  name                 = "pretix"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

# DB 비밀번호 보관함. 값은 콘솔에서 넣고 코드로 관리하지 않는다 (state에 남지 않게)
resource "aws_secretsmanager_secret" "db_password" {
  name = "pretix/db-password"
}
