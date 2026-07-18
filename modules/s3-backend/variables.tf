variable "state_bucket_name" {
  description = "Globally unique S3 bucket name used by the root backend"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table used by the root backend for state locking"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
