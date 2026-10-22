# TODO: AUTOMIGRATE=skip, pretix 이미지 버전 고정

data "aws_caller_identity" "current" {}

resource "aws_launch_template" "app" {
  name          = "${var.name_prefix}-lt"
  image_id      = var.ami_id
  instance_type = "t3.medium"

  iam_instance_profile {
    arn = var.instance_profile_arn
  }

  vpc_security_group_ids = [var.security_group_id]

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = "false"
      snapshot_id           = var.ami_snapshot_id
    }
  }

  # IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # 비밀번호(DB, SMTP)는 부팅 때 Secrets Manager에서 읽는다
  user_data = base64encode(templatefile("${path.module}/templates/user-data.sh.tftpl", {
    region        = var.region
    account_id    = data.aws_caller_identity.current.account_id
    public_url    = var.public_url
    mail_user     = var.mail_user
    django_secret = var.django_secret
  }))

  # 버전 설명은 콘솔에서 버전을 만들 때 적은 값
  lifecycle {
    ignore_changes = [description]
  }
}

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
  capacity_rebalance        = true

  # On-Demand 1대 + 나머지 Spot
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

  # 대시보드용 그룹 지표
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

  # 확장 정책, 예약 스케일링이 조정하는 값
  lifecycle {
    ignore_changes = [desired_capacity, min_size]
  }
}

# TODO: ALBRequestCountPerTarget으로 변경

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

resource "aws_ecr_repository" "pretix" {
  name                 = "pretix"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

# 값은 콘솔에서 관리 (state에 남지 않게)
resource "aws_secretsmanager_secret" "db_password" {
  name = "pretix/db-password"

  recovery_window_in_days = var.secret_recovery_window_days
}

# Gmail 앱 비밀번호
resource "aws_secretsmanager_secret" "smtp_password" {
  name = "pretix/smtp-password"

  recovery_window_in_days = var.secret_recovery_window_days
}

# 원서 마감 예약 스케일링. enable_scheduled_scaling이 false면 만들지 않음
resource "aws_autoscaling_schedule" "deadline" {
  for_each = var.enable_scheduled_scaling ? var.scaling_schedules : {}

  scheduled_action_name  = "${var.name_prefix}-${each.key}"
  autoscaling_group_name = aws_autoscaling_group.app.name
  recurrence             = each.value.recurrence
  time_zone              = "Asia/Seoul"
  min_size               = each.value.min_size
  max_size               = each.value.max_size
  desired_capacity       = each.value.desired_capacity
}
