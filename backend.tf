terraform {
  backend "s3" {
    bucket         = "django-app-terraform-state"
    key            = "lesson-7/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
