output "rds_postgres_endpoint" {
  description = "Endpoint of the standalone RDS PostgreSQL instance."
  value       = module.rds_postgres.endpoint
}

output "rds_postgres_secret_arn" {
  description = "Secrets Manager ARN holding the RDS master password."
  value       = module.rds_postgres.master_user_secret_arn
}

output "aurora_writer_endpoint" {
  description = "Writer endpoint of the Aurora cluster."
  value       = module.rds_aurora.endpoint
}

output "aurora_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster."
  value       = module.rds_aurora.reader_endpoint
}

output "aurora_secret_arn" {
  description = "Secrets Manager ARN holding the Aurora master password."
  value       = module.rds_aurora.master_user_secret_arn
}
