# 시나리오 3 부하테스트용. 확장 판단에 쓰는 값을 1분 단위로 한 화면에
# (CPU는 인스턴스 세부 모니터링이 켜져 있어야 1분마다 들어옴)

locals {
  tg_dims = ["TargetGroup", var.target_group_arn_suffix, "LoadBalancer", var.alb_arn_suffix]

  loadtest_widgets = [
    {
      x = 0, y = 0, width = 12, height = 7
      properties = {
        title       = "1. EC2 CPUUtilization (${var.asg_name}, avg)"
        stat        = "Average"
        metrics     = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name, { label = "CPU %" }]]
        yAxis       = { left = { min = 0, max = 100 } }
        annotations = { horizontal = [{ label = "scale-out target 60%", value = 60 }] }
      }
    },
    {
      x = 12, y = 0, width = 12, height = 7
      properties = {
        title = "2. ASG InService / Desired"
        stat  = "Maximum"
        metrics = [
          ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.asg_name, { label = "InService" }],
          ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", var.asg_name, { label = "Desired" }],
        ]
        yAxis = { left = { min = 0 } }
      }
    },
    {
      x = 0, y = 7, width = 8, height = 7
      properties = {
        title   = "3. RequestCount (${var.name_prefix}-tg)"
        stat    = "Sum"
        metrics = [concat(["AWS/ApplicationELB", "RequestCount"], local.tg_dims)]
        yAxis   = { left = { min = 0 } }
      }
    },
    {
      x = 8, y = 7, width = 8, height = 7
      properties = {
        title       = "4. TargetResponseTime p95 (sec, ${var.name_prefix}-tg)"
        stat        = "p95"
        metrics     = [concat(["AWS/ApplicationELB", "TargetResponseTime"], local.tg_dims)]
        yAxis       = { left = { min = 0 } }
        annotations = { horizontal = [{ label = "limit 2s", value = 2 }] }
      }
    },
    {
      x = 16, y = 7, width = 8, height = 7
      properties = {
        title   = "5. HealthyHostCount (${var.name_prefix}-tg)"
        stat    = "Minimum"
        metrics = [concat(["AWS/ApplicationELB", "HealthyHostCount"], local.tg_dims)]
        yAxis   = { left = { min = 0 } }
      }
    },
    {
      x = 0, y = 14, width = 24, height = 6
      properties = {
        title = "6. 5XX: ELB (load balancer) vs Target (app)"
        stat  = "Sum"
        metrics = [
          ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "ELB 5XX" }],
          concat(["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count"], local.tg_dims, [{ label = "Target 5XX" }]),
        ]
        yAxis = { left = { min = 0 } }
      }
    },
  ]
}

resource "aws_cloudwatch_dashboard" "loadtest" {
  dashboard_name = "${var.name_prefix}-test3"

  dashboard_body = jsonencode({
    start          = "-PT30M"
    periodOverride = "inherit"
    widgets = [
      for w in local.loadtest_widgets : merge(w, {
        type = "metric"
        properties = merge({
          view    = "timeSeries"
          stacked = false
          region  = var.region
          period  = 60
        }, w.properties)
      })
    ]
  })
}
