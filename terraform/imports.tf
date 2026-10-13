# 콘솔에서 만든 리소스 import. apply 후 삭제

# --- 네트워크 ---

import {
  to = module.network.aws_vpc.main
  id = "vpc-0dd4d4302df5ac369"
}

import {
  to = module.network.aws_internet_gateway.main
  id = "igw-06a56f1fa2699cec8"
}

import {
  to = module.network.aws_subnet.public["a"]
  id = "subnet-0d71e57aaab03a078"
}

import {
  to = module.network.aws_subnet.public["c"]
  id = "subnet-02725617dd5a06732"
}

import {
  to = module.network.aws_subnet.app["a"]
  id = "subnet-0f9e9f3f19896a5f8"
}

import {
  to = module.network.aws_subnet.app["c"]
  id = "subnet-0e106e00a8cf33f20"
}

import {
  to = module.network.aws_route_table.public
  id = "rtb-0b46ce0870e28a893"
}

import {
  to = module.network.aws_route_table.app
  id = "rtb-06b3627064ef36902"
}

# ID: 서브넷ID/라우팅테이블ID
import {
  to = module.network.aws_route_table_association.public["a"]
  id = "subnet-0d71e57aaab03a078/rtb-0b46ce0870e28a893"
}

import {
  to = module.network.aws_route_table_association.public["c"]
  id = "subnet-02725617dd5a06732/rtb-0b46ce0870e28a893"
}

import {
  to = module.network.aws_route_table_association.app["a"]
  id = "subnet-0f9e9f3f19896a5f8/rtb-06b3627064ef36902"
}

import {
  to = module.network.aws_route_table_association.app["c"]
  id = "subnet-0e106e00a8cf33f20/rtb-06b3627064ef36902"
}

import {
  to = module.network.aws_vpc_endpoint.s3
  id = "vpce-014add8bb5c9555f6"
}

# --- 보안그룹 ---

import {
  to = module.network.aws_security_group.alb
  id = "sg-022c5f9549f0ddb2d"
}

import {
  to = module.network.aws_security_group.app
  id = "sg-03d2e4c9675704e9f"
}

import {
  to = module.network.aws_security_group.nat
  id = "sg-0537dec35081ec06a"
}

import {
  to = module.network.aws_security_group.wg
  id = "sg-0e0b86d423e0f97ba"
}

# --- 보안그룹 규칙 ---

import {
  to = module.network.aws_vpc_security_group_ingress_rule.alb_http
  id = "sgr-0c518bc5a7dd0e46c"
}

import {
  to = module.network.aws_vpc_security_group_ingress_rule.app_http_from_alb
  id = "sgr-01dc0f346174205ee"
}

import {
  to = module.network.aws_vpc_security_group_ingress_rule.nat_from_app["a"]
  id = "sgr-08d0bb5cd56c05927"
}

import {
  to = module.network.aws_vpc_security_group_ingress_rule.nat_from_app["c"]
  id = "sgr-090d33cdb0416d544"
}

import {
  to = module.network.aws_vpc_security_group_ingress_rule.wg_tunnel
  id = "sgr-04f4d467a8a8c0143"
}

import {
  to = module.network.aws_vpc_security_group_ingress_rule.wg_from_app["a"]
  id = "sgr-05b474bcb69e0b6a9"
}

import {
  to = module.network.aws_vpc_security_group_ingress_rule.wg_from_app["c"]
  id = "sgr-084d6cbf743c2021b"
}

import {
  to = module.network.aws_vpc_security_group_egress_rule.all["alb"]
  id = "sgr-04a973c0616f2e4dd"
}

import {
  to = module.network.aws_vpc_security_group_egress_rule.all["app"]
  id = "sgr-0d6ac8b3390e55b2f"
}

import {
  to = module.network.aws_vpc_security_group_egress_rule.all["nat"]
  id = "sgr-00b0db855268f55e1"
}

import {
  to = module.network.aws_vpc_security_group_egress_rule.all["wg"]
  id = "sgr-06f1090350ef347ff"
}

# --- 앱 EC2 ---

import {
  to = module.app.aws_launch_template.app
  id = "lt-06a1b16ee390a4f49"
}

import {
  to = module.app.aws_autoscaling_group.app
  id = "pretix-demo-asg"
}

import {
  to = module.app.aws_autoscaling_policy.cpu
  id = "pretix-demo-asg/Target Tracking Policy"
}

# --- ALB ---

import {
  to = module.alb.aws_lb_target_group.app
  id = "arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:targetgroup/pretix-demo-tg/1c4e4d9e8d3fd23c"
}

import {
  to = module.alb.aws_lb.app
  id = "arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/pretix-demo-alb/12db2ff2dd71b2a8"
}

import {
  to = module.alb.aws_lb_listener.http
  id = "arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:listener/app/pretix-demo-alb/12db2ff2dd71b2a8/73db8926c6001b4d"
}

# --- NAT·WireGuard ---

import {
  to = module.gateway.aws_instance.nat
  id = "i-02973ca3225236c2c"
}

import {
  to = module.gateway.aws_instance.wg
  id = "i-054e45d0f128ee4a0"
}

import {
  to = module.gateway.aws_eip.wg
  id = "eipalloc-068726597784aa8b2"
}

import {
  to = module.gateway.aws_eip_association.wg
  id = "eipassoc-0e974b07465ef7f51"
}

# ID: 라우팅테이블ID_목적지
import {
  to = module.gateway.aws_route.app_internet
  id = "rtb-06b3627064ef36902_0.0.0.0/0"
}

import {
  to = module.gateway.aws_route.app_onprem
  id = "rtb-06b3627064ef36902_10.10.0.0/24"
}

# --- 알림 ---

import {
  to = module.monitoring.aws_sns_topic.alerts
  id = "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:${var.name_prefix}-alerts"
}

import {
  to = module.monitoring.aws_sns_topic_subscription.email
  id = "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:${var.name_prefix}-alerts:a988c7de-bd8c-43fb-b08d-90ae7ffd4695"
}

import {
  to = module.monitoring.aws_sns_topic_subscription.discord
  id = "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:${var.name_prefix}-alerts:8d7e3dc4-e8cc-4313-89c4-afe4c761efdf"
}

import {
  to = module.monitoring.aws_lambda_function.discord
  id = "pretix-demo-discord"
}

import {
  to = module.monitoring.aws_lambda_permission.sns
  id = "pretix-demo-discord/sns-pretix-demo-alerts"
}

import {
  to = module.monitoring.aws_cloudwatch_metric_alarm.cpu_high
  id = "pretix-demo-cpu-high"
}

import {
  to = module.monitoring.aws_cloudwatch_metric_alarm.latency_high
  id = "pretix-demo-latency-high"
}

import {
  to = module.monitoring.aws_cloudwatch_metric_alarm.unhealthy_host
  id = "pretix-demo-unhealthy-host"
}

import {
  to = module.monitoring.aws_cloudwatch_dashboard.main
  id = "pretix-demo"
}

# --- ECR, Secrets Manager ---

import {
  to = module.app.aws_ecr_repository.pretix
  id = "pretix"
}

import {
  to = module.app.aws_secretsmanager_secret.db_password
  id = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:pretix/db-password-xos7oY"
}

# --- WAF ---

# ID: 웹ACL ID/이름/범위
import {
  to = module.alb.aws_wafv2_web_acl.main
  id = "6da885ad-e174-4364-8845-9bfa418f8b38/pretix-demo-waf/REGIONAL"
}

# ID: 웹ACL ARN,ALB ARN
import {
  to = module.alb.aws_wafv2_web_acl_association.alb
  id = "arn:aws:wafv2:${var.region}:${data.aws_caller_identity.current.account_id}:regional/webacl/pretix-demo-waf/6da885ad-e174-4364-8845-9bfa418f8b38,arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/pretix-demo-alb/12db2ff2dd71b2a8"
}
