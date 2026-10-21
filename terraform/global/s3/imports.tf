# CLI로 만든 state 버킷 import. apply 후 삭제

import {
  to = aws_s3_bucket.tfstate
  id = "pretix-demo-tfstate-994114886472"
}

import {
  to = aws_s3_bucket_versioning.tfstate
  id = "pretix-demo-tfstate-994114886472"
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.tfstate
  id = "pretix-demo-tfstate-994114886472"
}

import {
  to = aws_s3_bucket_public_access_block.tfstate
  id = "pretix-demo-tfstate-994114886472"
}
