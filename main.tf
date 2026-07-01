provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# S3 backend bootstrap (S3 bucket + DynamoDB lock table для стану Terraform)
# Виконується один раз окремо від основного backend (див. коментар у backend.tf)
# ---------------------------------------------------------------------------
module "s3_backend" {
  source = "./modules/s3-backend"

  bucket_name    = "cicd-lesson-8-9-tf-state"
  dynamodb_table = "cicd-lesson-8-9-tf-locks"
  project_name   = var.project_name
  environment    = var.environment
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  azs                   = var.azs
}

# ---------------------------------------------------------------------------
# ECR
# ---------------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"

  repository_name = var.ecr_repository_name
  project_name     = var.project_name
  environment      = var.environment
}

# ---------------------------------------------------------------------------
# EKS
# ---------------------------------------------------------------------------
module "eks" {
  source = "./modules/eks"

  project_name         = var.project_name
  environment          = var.environment
  cluster_version      = var.eks_cluster_version
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  public_subnet_ids    = module.vpc.public_subnet_ids
  node_instance_types  = var.eks_node_instance_types
  desired_size         = var.eks_desired_size
  min_size             = var.eks_min_size
  max_size             = var.eks_max_size
}

# ---------------------------------------------------------------------------
# Providers для kubernetes/helm, що використовують дані щойно створеного EKS
# ---------------------------------------------------------------------------
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = module.eks.cluster_auth_token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = module.eks.cluster_auth_token
  }
}

# ---------------------------------------------------------------------------
# Jenkins (Helm, через Terraform) + Kubernetes agent (Kaniko + Git)
# ---------------------------------------------------------------------------
module "jenkins" {
  source = "./modules/jenkins"

  namespace     = var.jenkins_namespace
  project_name  = var.project_name
  ecr_repo_url  = module.ecr.repository_url
  aws_region    = var.aws_region

  depends_on = [module.eks]
}

# ---------------------------------------------------------------------------
# Argo CD (Helm, через Terraform) + Application, що стежить за Helm chart
# ---------------------------------------------------------------------------
module "argo_cd" {
  source = "./modules/argo_cd"

  namespace          = var.argocd_namespace
  project_name       = var.project_name
  git_repo_url       = var.git_repo_url
  git_repo_revision  = var.git_repo_revision
  chart_path         = var.django_app_chart_path
  target_namespace   = "django-app"

  depends_on = [module.eks]
}
