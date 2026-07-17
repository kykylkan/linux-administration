resource "aws_db_instance" "this" {
  count = var.engine == "postgres" ? 1 : 0

  identifier             = "${var.project_name}-db"
  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = var.instance_class
  allocated_storage      = 20
  storage_type           = "gp3"
  storage_encrypted      = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  multi_az                = false
  publicly_accessible     = false
  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = var.tags
}
