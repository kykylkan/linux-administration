variable "name" {
  description = "Base name/prefix used for all resources created by this module (subnet group, security group, parameter group, instance/cluster identifiers)"
  type        = string
}

variable "use_aurora" {
  description = "If true, the module provisions an Aurora cluster (aws_rds_cluster + aws_rds_cluster_instance). If false, it provisions a standalone aws_db_instance."
  type        = bool
  default     = false
}

variable "engine" {
  description = "Database engine. Standalone RDS: 'postgres' or 'mysql'. Aurora: 'aurora-postgresql' or 'aurora-mysql'."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version, e.g. '15.4' for postgres/aurora-postgresql, '8.0.mysql_aurora.3.05.2' for aurora-mysql. Leave null to let AWS pick the latest supported version for the family."
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "Parameter group family matching engine/engine_version, e.g. 'postgres15', 'aurora-postgresql15', 'mysql8.0', 'aurora-mysql8.0'."
  type        = string
}

variable "instance_class" {
  description = "Instance class used for the DB instance (standalone RDS) or for every instance in the Aurora cluster (e.g. db.t3.medium, db.r6g.large)."
  type        = string
  default     = "db.t3.medium"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment. Applies to standalone RDS only — Aurora achieves HA via multiple cluster instances (see aurora_instance_count) and ignores this flag."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where the database and its dedicated security group will be created."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs (private subnets recommended) used to build the DB subnet group. Needs at least 2 subnets in different AZs."
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the database on db_port. Leave empty if access is only granted via allowed_security_group_ids."
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security group IDs (e.g. EKS worker node SG, Jenkins agent SG) allowed to reach the database on db_port."
  type        = list(string)
  default     = []
}

variable "db_port" {
  description = "Port the database listens on (5432 for Postgres/Aurora-Postgres, 3306 for MySQL/Aurora-MySQL)."
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Name of the default database created inside the instance/cluster."
  type        = string
}

variable "master_username" {
  description = "Master username for the database."
  type        = string
  default     = "app_admin"
}

variable "master_password" {
  description = "Master password. Leave null (default) to let AWS Secrets Manager generate and manage it automatically — see manage_master_user_password."
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "When master_password is null, controls whether AWS Secrets Manager auto-generates and rotates the master password. Ignored if master_password is set."
  type        = bool
  default     = true
}

variable "allocated_storage" {
  description = "Allocated storage in GB. Standalone RDS only — Aurora storage is managed automatically and this value is ignored."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper limit (GB) for RDS storage autoscaling. Standalone RDS only."
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type for standalone RDS (gp3, gp2, io1). Ignored for Aurora."
  type        = string
  default     = "gp3"
}

variable "aurora_instance_count" {
  description = "Number of instances in the Aurora cluster (1 writer + N-1 readers). Ignored when use_aurora = false."
  type        = number
  default     = 1
}

variable "backup_retention_period" {
  description = "Number of days automated backups are retained."
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred daily backup window in UTC, format hh24:mi-hh24:mi."
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred weekly maintenance window in UTC, format ddd:hh24:mi-ddd:hh24:mi."
  type        = string
  default     = "mon:04:30-mon:05:30"
}

variable "deletion_protection" {
  description = "Enable AWS deletion protection on the instance/cluster. Recommended true for production."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "If true, no final snapshot is taken when the instance/cluster is destroyed. Set to false for production so 'terraform destroy' leaves a recovery snapshot."
  type        = bool
  default     = true
}

variable "publicly_accessible" {
  description = "Whether the database gets a publicly routable endpoint. Should stay false for anything beyond local experiments."
  type        = bool
  default     = false
}

variable "db_parameters" {
  description = "Extra DB/cluster parameters merged on top of the module defaults (max_connections, log_statement, work_mem). Keys/values are passed through to the parameter group as-is."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Common tags applied to every resource created by this module."
  type        = map(string)
  default     = {}
}
