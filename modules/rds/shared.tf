# Resources shared by both the Aurora and standalone-RDS code paths:
# DB subnet group + security group. Parameter groups differ by type
# (aws_db_parameter_group vs aws_rds_cluster_parameter_group) and therefore
# live in rds.tf / aurora.tf respectively, but share the same base parameter
# map defined below.

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-group"
  })
}

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Security group for the ${var.name} database (${var.use_aurora ? "Aurora cluster" : "RDS instance"})"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_cidr" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = var.db_port
  to_port           = var.db_port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.this.id
  description       = "Allow DB access from configured CIDR blocks"
}

resource "aws_security_group_rule" "ingress_sg" {
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.this.id
  description               = "Allow DB access from security group ${var.allowed_security_group_ids[count.index]}"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
}

locals {
  # Base parameters requested by the assignment: max_connections, log_statement, work_mem.
  # Merged with any extra parameters the caller supplies via var.db_parameters.
  base_db_parameters = {
    max_connections = "100"
    log_statement    = "ddl"
    work_mem         = "4096"
  }

  merged_db_parameters = merge(local.base_db_parameters, var.db_parameters)
}
