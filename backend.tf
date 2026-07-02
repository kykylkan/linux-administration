# Remote state backend. Fill in a bucket/table that already exist
# (e.g. created by the modules/s3-backend module from an earlier lesson)
# or comment this block out entirely to use local state while testing.

terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_YOUR_STATE_BUCKET"
    key            = "lesson-db-module/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "REPLACE_WITH_YOUR_LOCK_TABLE"
    encrypt        = true
  }
}
