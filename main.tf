data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# ---------------------------------------------------------------------------
# S3 + DynamoDB backend for Terraform state (bootstrap once with a local
# backend, then migrate state to S3 - see README "Bootstrap order").
# ---------------------------------------------------------------------------
module "s3_backend" {
  source       = "./modules/s3-backend"
  project_name = var.project_name
  tags         = var.tags
}

module "vpc" {
  source                = "./modules/vpc"
  project_name          = var.project_name
  vpc_cidr               = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  azs                   = var.azs
  tags                  = var.tags
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = var.ecr_repository_name
  tags            = var.tags
}

module "eks" {
  source              = "./modules/eks"
  project_name        = var.project_name
  cluster_version     = var.eks_cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size
  tags                = var.tags
}

module "rds" {
  source            = "./modules/rds"
  project_name      = var.project_name
  engine            = var.db_engine
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  instance_class    = var.db_instance_class
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  eks_node_sg_id    = module.eks.node_security_group_id
  tags              = var.tags

  depends_on = [module.eks]
}

module "jenkins" {
  source     = "./modules/jenkins"
  namespace  = "jenkins"
  tags       = var.tags

  depends_on = [module.eks]
}

module "argo_cd" {
  source      = "./modules/argo_cd"
  namespace   = "argocd"
  repo_url    = var.argocd_repo_url
  target_revision = "main"

  depends_on = [module.eks]
}

module "monitoring" {
  source    = "./modules/monitoring"
  namespace = "monitoring"
  tags      = var.tags

  depends_on = [module.eks]
}
