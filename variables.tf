variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project/prefix name used to build resource names."
  type        = string
  default     = "lesson-db"
}

variable "vpc_id" {
  description = "ID of an existing VPC to deploy the databases into."
  type        = string
}

variable "subnet_ids" {
  description = "List of (private) subnet IDs, spanning at least 2 AZs, for the DB subnet group."
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the databases."
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security group IDs (e.g. EKS node SG) allowed to connect to the databases."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Course      = "devops-lesson-db-module"
  }
}
