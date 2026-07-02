terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Example 1: standalone RDS PostgreSQL instance -------------------------
module "rds_postgres" {
  source = "./modules/rds"

  name       = "${var.project_name}-rds"
  use_aurora = false

  engine                  = "postgres"
  engine_version          = "15.4"
  parameter_group_family  = "postgres15"
  instance_class          = "db.t3.medium"
  multi_az                = false

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  allowed_cidr_blocks        = var.allowed_cidr_blocks
  allowed_security_group_ids = var.allowed_security_group_ids

  db_port         = 5432
  db_name         = "app_db"
  master_username = "app_admin"
  # master_password left null on purpose -> AWS Secrets Manager generates and manages it

  allocated_storage     = 20
  max_allocated_storage = 100

  skip_final_snapshot = true

  db_parameters = {
    max_connections = "200"
  }

  tags = var.tags
}

# --- Example 2: Aurora PostgreSQL cluster (toggle via use_aurora) ----------
module "rds_aurora" {
  source = "./modules/rds"

  name       = "${var.project_name}-aurora"
  use_aurora = true

  engine                  = "aurora-postgresql"
  engine_version          = "15.4"
  parameter_group_family  = "aurora-postgresql15"
  instance_class          = "db.r6g.large"
  aurora_instance_count   = 2 # 1 writer + 1 reader

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  allowed_cidr_blocks        = var.allowed_cidr_blocks
  allowed_security_group_ids = var.allowed_security_group_ids

  db_port         = 5432
  db_name         = "app_db"
  master_username = "app_admin"

  skip_final_snapshot = true

  tags = var.tags
}
