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

# ── S3 backend bootstrap (only needed once) ──────────────────────────────────
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = var.state_bucket_name
  table_name  = var.state_lock_table
  environment = var.environment
}

# ── VPC (re-uses existing module from prev HW) ───────────────────────────────
module "vpc" {
  source             = "./modules/vpc"
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
}

# ── ECR ──────────────────────────────────────────────────────────────────────
module "ecr" {
  source          = "./modules/ecr"
  repository_name = var.ecr_repository_name
  environment     = var.environment
}

# ── EKS ──────────────────────────────────────────────────────────────────────
module "eks" {
  source          = "./modules/eks"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  node_group_name = var.node_group_name
  instance_types  = var.instance_types
  desired_size    = var.desired_size
  min_size        = var.min_size
  max_size        = var.max_size
  environment     = var.environment
}
