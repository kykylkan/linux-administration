resource "aws_db_parameter_group" "postgres" {
  count = var.use_aurora ? 0 : 1

  name   = "${var.project_name}-postgres"
  family = var.postgres_parameter_group_family

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = var.tags
}

resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1

  identifier        = "${var.project_name}-db"
  engine            = "postgres"
  engine_version    = var.postgres_engine_version
  instance_class    = var.instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  parameter_group_name        = aws_db_parameter_group.postgres[0].name

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  multi_az                = false
  publicly_accessible     = false
  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = var.tags
}
