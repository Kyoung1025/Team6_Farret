# state 버킷. 메인 코드(terraform/)와 state를 분리해서 관리
# 메인 코드를 destroy해도 이 버킷은 남는다

terraform {
  required_version = "~> 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.67"
    }
  }

  backend "s3" {
    bucket       = "pretix-demo-tfstate-994114886472"
    key          = "global/s3/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "ap-northeast-2"

  default_tags {
    tags = {
      Project = "pretix-demo"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "tfstate" {
  bucket = "pretix-demo-tfstate-${data.aws_caller_identity.current.account_id}"

  # 지우면 모든 state가 사라짐
  lifecycle {
    prevent_destroy = true
  }
}

# 잘못 덮어쓴 state를 이전 버전으로 되돌릴 수 있게
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_name" {
  description = "state 버킷 이름"
  value       = aws_s3_bucket.tfstate.bucket
}
