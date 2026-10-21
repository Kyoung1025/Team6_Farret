# 알람 → SNS → 이메일, Lambda(디스코드), Lambda(자동 전환)

data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# --- 디스코드 알림 ---

resource "aws_sns_topic_subscription" "discord" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.discord.arn
}

data "archive_file" "discord" {
  type        = "zip"
  source_file = var.lambda_source_file
  output_path = "${path.module}/.build/discord-notifier.zip"
}

resource "aws_cloudwatch_log_group" "discord" {
  name              = "/aws/lambda/${var.name_prefix}-discord"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "discord" {
  function_name    = "${var.name_prefix}-discord"
  role             = var.lambda_role_arn
  runtime          = "python3.14"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.discord.output_path
  source_code_hash = data.archive_file.discord.output_base64sha256

  environment {
    variables = {
      WEBHOOK_URL = var.discord_webhook_url
    }
  }
}

resource "aws_lambda_permission" "sns" {
  statement_id  = "sns-${var.name_prefix}-alerts"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

# --- 자동 전환 ---
# aws-unhealthy 경보가 오면 리스너 가중치를 AWS 0 : 온프렘 100으로 바꾼다.
# 온프렘이 unhealthy면 안 바꾼다. 복귀는 사람이 한다

resource "aws_iam_role" "failover" {
  name = "${var.name_prefix}-failover-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "failover_logs" {
  role       = aws_iam_role.failover.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 가중치 변경은 이 리스너에만. 상태 조회는 리소스를 못 좁혀서 *
resource "aws_iam_role_policy" "failover" {
  name = "alb-weight"
  role = aws_iam_role.failover.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "elasticloadbalancing:ModifyListener"
        Resource = var.listener_arn
      },
      {
        Effect   = "Allow"
        Action   = "elasticloadbalancing:DescribeTargetHealth"
        Resource = "*"
      },
    ]
  })
}

data "archive_file" "failover" {
  type        = "zip"
  source_file = var.failover_source_file
  output_path = "${path.module}/.build/failover.zip"
}

resource "aws_cloudwatch_log_group" "failover" {
  name              = "/aws/lambda/${var.name_prefix}-failover"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "failover" {
  function_name    = "${var.name_prefix}-failover"
  role             = aws_iam_role.failover.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  timeout          = 30
  filename         = data.archive_file.failover.output_path
  source_code_hash = data.archive_file.failover.output_base64sha256

  environment {
    variables = {
      LISTENER_ARN  = var.listener_arn
      AWS_TG_ARN    = var.target_group_arn
      ONPREM_TG_ARN = var.onprem_target_group_arn
      WEBHOOK_URL   = var.discord_webhook_url
    }
  }
}

resource "aws_lambda_permission" "failover_sns" {
  statement_id  = "sns-alerts"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failover.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

resource "aws_sns_topic_subscription" "failover" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.failover.arn
}

# --- 알람 (노션 모니터링 문서 6번) ---
# OK 알림은 보내지 않는다

locals {
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# 이름이 failover Lambda 코드에 박혀 있다. 바꾸면 Lambda도 같이
resource "aws_cloudwatch_metric_alarm" "aws_unhealthy" {
  alarm_name          = "${var.name_prefix}-aws-unhealthy"
  alarm_description   = "AWS app target group has no healthy targets. Consider switching ALB weight to on-prem."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching" # 서버가 0대면 ALB가 지표를 안 보냄
  alarm_actions       = local.alarm_actions

  dimensions = {
    TargetGroup  = var.target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name_prefix}-alb-5xx"
  alarm_description   = "ALB returned 5xx (ELB level) 10 or more times in 5 minutes."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name          = "${var.name_prefix}-target-5xx"
  alarm_description   = "Targets (AWS app or on-prem) returned 5xx 20 or more times in 5 minutes."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 20
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
}

# --- 대시보드 (노션 6번 순서) ---

locals {
  lb = var.alb_arn_suffix

  # 그래프 패널. 9번(텍스트)은 따로
  panels = [
    {
      title   = "1. AWS TG HealthyHostCount"
      stat    = "Minimum"
      period  = 60
      yAxis   = { left = { min = 0 } }
      metrics = [["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", var.target_group_arn_suffix, "LoadBalancer", local.lb]]
    },
    {
      title   = "2. On-prem TG HealthyHostCount"
      stat    = "Minimum"
      period  = 60
      yAxis   = { left = { min = 0, max = 1 } }
      metrics = [["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", var.onprem_target_group_arn_suffix, "LoadBalancer", local.lb]]
    },
    {
      title   = "3. ALB RequestCount"
      stat    = "Sum"
      period  = 60
      metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.lb]]
    },
    {
      title   = "4. HTTPCode_ELB_5XX_Count"
      stat    = "Sum"
      period  = 60
      metrics = [["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", local.lb]]
    },
    {
      title   = "5. HTTPCode_Target_5XX_Count"
      stat    = "Sum"
      period  = 60
      metrics = [["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.lb]]
    },
    {
      title   = "6. TargetResponseTime p95 (초)"
      stat    = "p95"
      period  = 60
      metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.lb]]
    },
    {
      title   = "7. ASG GroupInServiceInstances"
      stat    = "Maximum"
      period  = 60
      yAxis   = { left = { min = 0 } }
      metrics = [["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.asg_name]]
    },
    {
      title  = "8. EC2 CPUUtilization / Network (ASG)"
      stat   = "Average"
      period = 300
      metrics = [
        ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name, { stat = "Average", label = "CPU %" }],
        ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", var.asg_name, { label = "NetworkIn", yAxis = "right", stat = "Sum" }],
        ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", var.asg_name, { label = "NetworkOut", yAxis = "right", stat = "Sum" }],
      ]
    },
    {
      title   = "10. WAF CountedRequests (선택)"
      stat    = "Sum"
      period  = 300
      metrics = [["AWS/WAFV2", "CountedRequests", "WebACL", var.waf_name, "Region", var.region, "Rule", "ALL"]]
    },
  ]

  wg_text = "### 9. WG Hub HandshakeAgeSeconds (선택)\n\n아직 수집하지 않음. 허브에서 `wg show`의 마지막 핸드셰이크 경과 시간을 1분마다 `Pretix/WG` 네임스페이스로 보내야 그래프가 생김."

  # y축 설정이 없는 패널은 키 자체를 빼야 콘솔 값과 같다
  graphs = [
    for p in local.panels : {
      type   = "metric"
      x      = 0
      width  = 24
      height = 6
      properties = merge(
        {
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = p.title
          stat    = p.stat
          period  = p.period
          metrics = p.metrics
        },
        { for k, v in { yAxis = try(p.yAxis, null) } : k => v if v != null },
      )
    }
  ]
}

# 3칸 × 2줄(1~6), 2칸 × 2줄(7~10). 10/21 콘솔에서 이 배치로 바꿈
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.name_prefix

  dashboard_body = jsonencode({
    start = "-PT1H"
    widgets = concat(
      [for i, p in slice(local.graphs, 0, 6) : merge(p, { x = (i % 3) * 8, y = floor(i / 3) * 6, width = 8 })],
      [for i, p in slice(local.graphs, 6, 8) : merge(p, { x = i * 12, y = 12, width = 12 })],
      [{
        type       = "text"
        x          = 0
        y          = 18
        width      = 12
        height     = 6
        properties = { markdown = local.wg_text }
      }],
      [merge(local.graphs[8], { x = 12, y = 18, width = 12 })],
    )
  })
}
