terraform {
  required_version = "~> 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.67" # 6.67 이상 7.0 미만
    }
  }

  # state 파일을 팀 공용 S3 버킷에 둔다
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

# --- 모듈 조립: 앞 모듈의 출력이 다음 모듈의 입력이 된다 ---

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
}

module "app" {
  source = "./modules/app"

  name_prefix       = var.name_prefix
  region            = var.region
  ami_id            = var.app_ami_id
  ami_snapshot_id   = var.app_ami_snapshot_id
  subnet_ids        = module.network.app_subnet_ids
  security_group_id = module.network.security_group_ids["app"]
  target_group_arn  = module.alb.target_group_arn
  public_url        = var.pretix_public_url
  allowed_hosts     = var.pretix_allowed_hosts
}

# 로그인한 계정의 ID (import할 ALB ARN에 사용)
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

module "gateway" {
  source = "./modules/gateway"

  name_prefix           = var.name_prefix
  subnet_id             = module.network.public_subnet_ids[0] # public-a
  nat_ami_id            = var.nat_ami_id
  wg_ami_id             = var.app_ami_id # 앱 EC2와 같은 Ubuntu 24.04
  nat_security_group_id = module.network.security_group_ids["nat"]
  wg_security_group_id  = module.network.security_group_ids["wg"]
  instance_profile_name = "${var.name_prefix}-infra-role"
  app_route_table_id    = module.network.app_route_table_id
  onprem_tunnel_cidr    = var.onprem_tunnel_cidr
}
