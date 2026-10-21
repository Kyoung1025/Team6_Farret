resource "aws_lb_target_group" "app" {
  name                 = "${var.name_prefix}-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 30

  # 앱 서버의 nginx가 /healthcheck/에 바로 200을 준다 (pretix, DB는 안 봄)
  health_check {
    path                = "/healthcheck/"
    matcher             = "200"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 5
    timeout             = 4
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # 세션 고정은 리스너(대상 그룹 단위)에서 한다
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 3600
    enabled         = false
  }
}

# 온프렘 (WireGuard 터널 너머 10.10.0.2:80, k3s nginx). 평소 가중치 0, 장애 때 올린다
# 이름은 콘솔에서 만든 그대로 (바꾸면 새로 만들어짐)
resource "aws_lb_target_group" "onprem" {
  name        = "pretix-onprem-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # 온프렘 nginx가 Host를 pretix url로 바꿔 넘겨서 200을 받는다
  health_check {
    path                = "/healthcheck/"
    matcher             = "200"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }
}

# VPC 밖 IP라서 availability_zone = "all"
resource "aws_lb_target_group_attachment" "onprem" {
  target_group_arn  = aws_lb_target_group.onprem.arn
  target_id         = var.onprem_target_ip
  port              = 80
  availability_zone = "all"
}

resource "aws_lb" "app" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  subnets            = var.subnet_ids
  security_groups    = [var.security_group_id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  # 가중치로 AWS / 온프렘 비율을 정한다.
  # AWS 앱은 서버마다 Redis가 따로라서 대상 그룹 단위로 1시간 세션 고정
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.app.arn
        weight = var.weight_app
      }
      target_group {
        arn    = aws_lb_target_group.onprem.arn
        weight = var.weight_onprem
      }
      stickiness {
        enabled  = true
        duration = 3600
      }
    }
  }

  # 장애 때 failover Lambda가 가중치를 0:100으로 바꾸고, 복귀는 사람이 한다.
  # apply가 그걸 되돌리지 않게 처음 만들 때만 위 값을 쓴다
  lifecycle {
    ignore_changes = [default_action]
  }
}

# 관리형 규칙 2개, 둘 다 Count 모드 (차단 안 함)

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.name_prefix}-waf"
  description = "${var.name_prefix}-waf"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 0

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    }
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
  }
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.app.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
