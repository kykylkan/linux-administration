output "endpoint" {
  value = var.engine == "postgres" ? aws_db_instance.this[0].endpoint : aws_rds_cluster.this[0].endpoint
  sensitive = true
}

output "db_name" {
  value = var.db_name
}
