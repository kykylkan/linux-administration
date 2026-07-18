terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3_backend" {
  source = "../modules/s3-backend"

  state_bucket_name = var.state_bucket_name
  lock_table_name   = var.lock_table_name
  tags              = var.tags
}

moved {
  from = aws_s3_bucket.terraform_state
  to   = module.s3_backend.aws_s3_bucket.terraform_state
}

moved {
  from = aws_s3_bucket_versioning.terraform_state
  to   = module.s3_backend.aws_s3_bucket_versioning.terraform_state
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.terraform_state
  to   = module.s3_backend.aws_s3_bucket_server_side_encryption_configuration.terraform_state
}

moved {
  from = aws_s3_bucket_public_access_block.terraform_state
  to   = module.s3_backend.aws_s3_bucket_public_access_block.terraform_state
}

moved {
  from = aws_dynamodb_table.terraform_locks
  to   = module.s3_backend.aws_dynamodb_table.terraform_locks
}
