output "state_bucket_name" {
  value = module.s3_backend.bucket_name
}

output "lock_table_name" {
  value = module.s3_backend.dynamodb_table_name
}
