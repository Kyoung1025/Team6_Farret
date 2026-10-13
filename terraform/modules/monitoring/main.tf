# monitoring/design.md의 알림 구성을 코드로 옮긴 것
# CloudWatch 알람 → SNS 토픽 → 이메일 + Lambda → 디스코드

# --- SNS 토픽과 구독 ---

resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_sns_topic_subscription" "discord" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.discord.arn
}

# --- 디스코드로 보내는 Lambda ---

# monitoring/discord-notifier/lambda_function.py를 zip으로 묶는다
data "archive_file" "discord" {
  type        = "zip"
  source_file = var.lambda_source_file
  output_path = "${path.module}/.build/discord-notifier.zip"
}

resource "aws_lambda_function" "discord" {
  function_name    = "${var.name_prefix}-discord"
  role             = var.lambda_role_arn
  runtime          = "python3.14"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.discord.output_path
  source_code_hash = data.archive_file.discord.output_base64sha256

  # 웹훅 URL은 코드에 두지 않고 terraform.tfvars(커밋 안 됨)에서 받는다
  environment {
    variables = {
      WEBHOOK_URL = var.discord_webhook_url
    }
  }
}

# SNS가 이 Lambda를 부를 수 있게 허용
resource "aws_lambda_permission" "sns" {
  statement_id  = "sns-${var.name_prefix}-alerts"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

# --- 알람 ---

locals {
  alarm_actions = [aws_sns_topic.alerts.arn]

  # 콘솔에서 만들 때 가용 영역이 ap-northeast-2a 하나로 들어갔다 (c 영역 서버는 안 잡힘)
  alb_dimensions = {
    LoadBalancer     = var.alb_arn_suffix
    TargetGroup      = var.target_group_arn_suffix
    AvailabilityZone = "ap-northeast-2a"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name_prefix}-cpu-high"
  alarm_description   = "서버 CPU 80% 초과 (5분)"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { AutoScalingGroupName = var.asg_name }
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "latency_high" {
  alarm_name          = "${var.name_prefix}-latency-high"
  alarm_description   = "응답 시간 p95 2초 초과 (3분)"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = local.alb_dimensions
  extended_statistic  = "p95"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  threshold           = 2
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_host" {
  alarm_name          = "${var.name_prefix}-unhealthy-host"
  alarm_description   = "비정상 서버 (2분)"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  dimensions          = local.alb_dimensions
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

# --- 대시보드 ---

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.name_prefix

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 6
        height = 6
        properties = {
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "ALB 요청 수"
          stat    = "Sum"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 0
        width  = 6
        height = 6
        properties = {
          metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { region = var.region }]]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "응답 시간 p95 (초)"
          stat    = "p95"
          period  = 60
          annotations = {
            horizontal = [
              { color = "#1f77b4", label = "정상 기준", value = 2 },
              { color = "#d62728", label = "장애 기준", value = 5 },
            ]
          }
        }
      },
    ]
  })
}
