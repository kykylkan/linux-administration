variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# ── S3 backend ───────────────────────────────────────────────────────────────
variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "django-app-terraform-state"
}

variable "state_lock_table" {
  description = "DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock"
}

# ── VPC ───────────────────────────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

# ── ECR ───────────────────────────────────────────────────────────────────────
variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "django-app"
}

# ── EKS ───────────────────────────────────────────────────────────────────────
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "django-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "node_group_name" {
  description = "EKS node group name"
  type        = string
  default     = "django-nodes"
}

variable "instance_types" {
  description = "EC2 instance types for node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}
