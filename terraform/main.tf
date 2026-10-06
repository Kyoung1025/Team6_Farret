terraform {
  required_version = "~> 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.67" # 6.67 이상 7.0 미만
    }
  }

  # 버킷 이름에 계정 ID가 들어가서, IAM 사용자를 받은 뒤 채운다
  # backend "s3" {
  #   bucket       = "pretix-demo-tfstate-<계정ID>"
  #   key          = "pretix-demo/terraform.tfstate"
  #   region       = "ap-northeast-2"
  #   use_lockfile = true # S3 자체 락. 두 사람이 동시에 apply하는 것을 막는다
  #   encrypt      = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = var.project
    }
  }
}
