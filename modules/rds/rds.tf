# Standalone RDS instance path — created only when var.use_aurora = false.

resource "aws_db_parameter_group" "this" {
  count = var.use_aurora ? 0 : 1

  name   = "${var.name}-pg"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = local.merged_db_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1

  identifier     = var.name
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type           = var.storage_type
  storage_encrypted      = true

  db_name  = var.db_name
  username = var.master_username

  password                     = var.master_password
  manage_master_user_password  = var.master_password == null ? var.manage_master_user_password : false

  port = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.this[0].name

  multi_az             = var.multi_az
  publicly_accessible  = var.publicly_accessible
  deletion_protection  = var.deletion_protection

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"

  backup_retention_period = var.backup_retention_period
  backup_window            = var.backup_window
  maintenance_window       = var.maintenance_window

  tags = merge(var.tags, {
    Name = var.name
  })
}
