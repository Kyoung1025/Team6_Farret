# AWS 구축 가이드 7번(ALB)을 코드로 옮긴 것. WAF는 별도로 다룬다

# --- 대상 그룹: ASG가 서버를 넣고 뺀다 ---

resource "aws_lb_target_group" "app" {
  name                 = "${var.name_prefix}-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 60

  # pretix의 /healthcheck/는 DB와 Redis 연결까지 확인한다
  health_check {
    path                = "/healthcheck/"
    matcher             = "200-399"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  # 고정 세션: 앱 서버마다 Redis가 따로라서 같은 사용자를 같은 서버로 보낸다
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 3600
    enabled         = true
  }
}

# --- ALB: 인터넷에서 받는 입구 ---

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

  # 콘솔이 만든 형식(가중치 1, 리스너 단위 고정 세션 끔)과 같게 둔다
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.app.arn
        weight = 1
      }
      stickiness {
        enabled  = false
        duration = 3600
      }
    }
  }
}
