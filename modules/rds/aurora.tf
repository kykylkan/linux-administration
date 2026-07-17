resource "aws_rds_cluster" "this" {
  count = var.engine == "aurora-postgresql" ? 1 : 0

  cluster_identifier     = "${var.project_name}-aurora"
  engine                 = "aurora-postgresql"
  engine_version         = "15.4"
  database_name          = var.db_name
  master_username        = var.db_username
  master_password        = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  backup_retention_period = 7
  skip_final_snapshot     = true
  storage_encrypted       = true

  tags = var.tags
}

resource "aws_rds_cluster_instance" "this" {
  count              = var.engine == "aurora-postgresql" ? 2 : 0
  identifier         = "${var.project_name}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.this[0].id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this[0].engine
  engine_version     = aws_rds_cluster.this[0].engine_version

  tags = var.tags
}
