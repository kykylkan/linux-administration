output "endpoint" {
  description = "Connection endpoint — cluster writer endpoint for Aurora, instance address for standalone RDS."
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
}

output "reader_endpoint" {
  description = "Aurora reader (load-balanced read replica) endpoint. Null for standalone RDS."
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : null
}

output "port" {
  description = "Port the database is listening on."
  value       = var.db_port
}

output "security_group_id" {
  description = "ID of the security group attached to the database."
  value       = aws_security_group.this.id
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group used by the instance/cluster."
  value       = aws_db_subnet_group.this.name
}

output "database_name" {
  description = "Name of the default database."
  value       = var.db_name
}

output "master_username" {
  description = "Master username."
  value       = var.master_username
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the auto-generated master password (only set when manage_master_user_password is effectively true)."
  value = var.use_aurora ? (
    length(aws_rds_cluster.this[0].master_user_secret) > 0 ? aws_rds_cluster.this[0].master_user_secret[0].secret_arn : null
    ) : (
    length(aws_db_instance.this[0].master_user_secret) > 0 ? aws_db_instance.this[0].master_user_secret[0].secret_arn : null
  )
}

output "cluster_id" {
  description = "Aurora cluster identifier. Null for standalone RDS."
  value       = var.use_aurora ? aws_rds_cluster.this[0].id : null
}

output "cluster_instance_ids" {
  description = "IDs of Aurora cluster instances. Empty list for standalone RDS."
  value       = var.use_aurora ? aws_rds_cluster_instance.this[*].id : []
}

output "instance_id" {
  description = "Standalone RDS instance identifier. Null for Aurora."
  value       = var.use_aurora ? null : aws_db_instance.this[0].id
}
