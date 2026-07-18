output "endpoint" {
  value     = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
  sensitive = true
}

output "reader_endpoint" {
  value     = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : null
  sensitive = true
}

output "port" {
  value = 5432
}

output "master_user_secret_arn" {
  value = var.use_aurora ? aws_rds_cluster.this[0].master_user_secret[0].secret_arn : aws_db_instance.this[0].master_user_secret[0].secret_arn
}

output "db_name" {
  value = var.db_name
}
