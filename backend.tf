# Backend для збереження стану Terraform.
# УВАГА: бакет і DynamoDB таблиця, вказані нижче, створюються модулем
# modules/s3-backend. Перед першим `terraform init` з цим backend-ом
# їх потрібно створити окремо (bootstrap), наприклад:
#
#   terraform init                       # без backend "s3" (закоментувати блок нижче)
#   terraform apply -target=module.s3_backend
#   # розкоментувати backend "s3" і виконати:
#   terraform init -migrate-state
#
terraform {
  backend "s3" {
    bucket         = "cicd-lesson-8-9-tf-state"
    key            = "lesson-8-9/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "cicd-lesson-8-9-tf-locks"
    encrypt        = true
  }
}
