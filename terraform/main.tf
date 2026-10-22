terraform {
  required_version = "~> 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.67" # 6.67 이상 7.0 미만
    }
    # Lambda zip 패키징
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.8"
    }
  }

  # state 파일을 팀 공용 S3 버킷에 둠
  backend "s3" {
    bucket       = "pretix-demo-tfstate-994114886472"
    key          = "pretix-demo/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true # S3 자체 락. 두 사람이 동시에 apply하는 것을 막는다
    encrypt      = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = var.project
    }
  }
}

# --- 모듈 조립 ---

module "network" {
  source = "./modules/network"

  name_prefix        = var.name_prefix
  region             = var.region
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  app_subnets        = var.app_subnets
  onprem_public_cidr = var.onprem_public_cidr
}

module "alb" {
  source = "./modules/alb"

  name_prefix       = var.name_prefix
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.public_subnet_ids
  security_group_id = module.network.security_group_ids["alb"]
  weight_app        = var.alb_weight_app
  weight_onprem     = var.alb_weight_onprem
}

module "iam" {
  source = "./modules/iam"

  name_prefix = var.name_prefix
  region      = var.region
}

module "app" {
  source = "./modules/app"

  name_prefix          = var.name_prefix
  region               = var.region
  instance_profile_arn = module.iam.app_instance_profile_arn
  ami_id               = var.app_ami_id
  ami_snapshot_id      = var.app_ami_snapshot_id
  subnet_ids           = module.network.app_subnet_ids
  security_group_id    = module.network.security_group_ids["app"]
  target_group_arn     = module.alb.target_group_arn
  public_url           = var.pretix_public_url
  mail_user            = var.pretix_mail_user
  django_secret        = var.pretix_django_secret

  secret_recovery_window_days = var.secret_recovery_window_days

  enable_scheduled_scaling = var.enable_scheduled_scaling
  scaling_schedules        = var.scaling_schedules
}

module "gateway" {
  source = "./modules/gateway"

  name_prefix           = var.name_prefix
  region                = var.region
  subnet_id             = module.network.public_subnet_ids[0] # public-a
  public_subnet_ids     = module.network.public_subnet_ids
  nat_ami_id            = var.nat_ami_id
  wg_ami_id             = var.wg_ami_id
  nat_security_group_id = module.network.security_group_ids["nat"]
  wg_security_group_id  = module.network.security_group_ids["wg"]
  instance_profile_name = module.iam.infra_instance_profile_name
  app_route_table_id    = module.network.app_route_table_id
  public_route_table_id = module.network.public_route_table_id
  onprem_tunnel_cidr    = var.onprem_tunnel_cidr
}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix             = var.name_prefix
  region                  = var.region
  asg_name                = module.app.asg_name
  alb_arn_suffix          = module.alb.arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  alert_email             = var.alert_email
  discord_webhook_url     = var.discord_webhook_url
  lambda_role_arn         = module.iam.lambda_alert_role_arn
  lambda_source_file      = "${path.root}/../monitoring/discord-notifier/lambda_function.py"

  listener_arn                   = module.alb.listener_arn
  target_group_arn               = module.alb.target_group_arn
  onprem_target_group_arn        = module.alb.onprem_target_group_arn
  onprem_target_group_arn_suffix = module.alb.onprem_target_group_arn_suffix
  waf_name                       = module.alb.waf_name
  failover_source_file           = "${path.root}/../monitoring/failover/lambda_function.py"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}
