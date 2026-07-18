variable "aws_region" {
  description = "AWS region containing the Terraform state resources"
  type        = string
  default     = "eu-central-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name used by the root backend"
  type        = string
  default     = "devops-final-project-tfstate"
}

variable "lock_table_name" {
  description = "DynamoDB table used by the root backend for state locking"
  type        = string
  default     = "devops-final-project-tf-lock"
}

variable "tags" {
  type = map(string)
  default = {
    Project   = "devops-final"
    ManagedBy = "terraform-bootstrap"
  }
}
