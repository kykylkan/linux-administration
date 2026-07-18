variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project/name prefix used for tagging and resource naming"
  type        = string
  default     = "devops-final"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.128.0/20", "10.0.144.0/20"]
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.33"
}

variable "eks_node_instance_types" {
  description = "Instance types for the EKS managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  type    = number
  default = 2
}

variable "eks_node_min_size" {
  type    = number
  default = 2
}

variable "eks_node_max_size" {
  type    = number
  default = 4
}

variable "use_aurora" {
  description = "Create an Aurora PostgreSQL cluster instead of a standalone RDS instance"
  type        = bool
  default     = false
}

variable "db_name" {
  type    = string
  default = "django_app"
}

variable "db_username" {
  type      = string
  default   = "django_admin"
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "postgres_engine_version" {
  type    = string
  default = "16.14"
}

variable "aurora_engine_version" {
  type    = string
  default = "15.17"
}

variable "postgres_parameter_group_family" {
  type    = string
  default = "postgres16"
}

variable "aurora_parameter_group_family" {
  type    = string
  default = "aurora-postgresql15"
}

variable "db_parameters" {
  description = "PostgreSQL parameters applied to the selected database"
  type        = map(string)
  default = {
    log_statement = "ddl"
    work_mem      = "16384"
  }
}

variable "aurora_instance_count" {
  type    = number
  default = 2
}

variable "ecr_repository_name" {
  type    = string
  default = "django-app"
}

variable "argocd_repo_url" {
  description = "Git repository URL that Argo CD will track for app manifests (this repo, charts/ path)"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project   = "devops-final"
    ManagedBy = "terraform"
  }
}
