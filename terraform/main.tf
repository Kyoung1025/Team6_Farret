terraform {
  required_version = "~> 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.67" # 6.67 이상 7.0 미만
    }
  }

  # state 파일을 팀 공용 S3 버킷에 둔다 (버킷은 CLI로 따로 만들었고 destroy 대상이 아니다)
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
