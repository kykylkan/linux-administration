resource "aws_rds_cluster_parameter_group" "aurora" {
  count = var.use_aurora ? 1 : 0

  name   = "${var.project_name}-aurora-postgres"
  family = var.aurora_parameter_group_family

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = var.tags
}

resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier              = "${var.project_name}-aurora"
  engine                          = "aurora-postgresql"
  engine_version                  = var.aurora_engine_version
  database_name                   = var.db_name
  master_username                 = var.db_username
  manage_master_user_password     = true
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora[0].name

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  backup_retention_period = 7
  skip_final_snapshot     = true
  storage_encrypted       = true

  tags = var.tags
}

resource "aws_rds_cluster_instance" "this" {
  count              = var.use_aurora ? var.aurora_instance_count : 0
  identifier         = "${var.project_name}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.this[0].id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this[0].engine
  engine_version     = aws_rds_cluster.this[0].engine_version

  tags = var.tags
}
