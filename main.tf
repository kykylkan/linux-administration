data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.aws_region,
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.aws_region,
      ]
    }
  }
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }

  depends_on = [module.eks]
}

module "vpc" {
  source               = "./modules/vpc"
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  tags                 = var.tags
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = var.ecr_repository_name
  tags            = var.tags
}

module "secrets" {
  source       = "./modules/secrets"
  project_name = var.project_name
  tags         = var.tags
}

module "eks" {
  source                      = "./modules/eks"
  project_name                = var.project_name
  cluster_version             = var.eks_cluster_version
  cluster_admin_principal_arn = data.aws_caller_identity.current.arn
  vpc_id                      = module.vpc.vpc_id
  private_subnet_ids          = module.vpc.private_subnet_ids
  public_subnet_ids           = module.vpc.public_subnet_ids
  node_instance_types         = var.eks_node_instance_types
  node_desired_size           = var.eks_node_desired_size
  node_min_size               = var.eks_node_min_size
  node_max_size               = var.eks_node_max_size
  tags                        = var.tags
}

module "rds" {
  source                          = "./modules/rds"
  project_name                    = var.project_name
  use_aurora                      = var.use_aurora
  db_name                         = var.db_name
  db_username                     = var.db_username
  instance_class                  = var.db_instance_class
  postgres_engine_version         = var.postgres_engine_version
  aurora_engine_version           = var.aurora_engine_version
  postgres_parameter_group_family = var.postgres_parameter_group_family
  aurora_parameter_group_family   = var.aurora_parameter_group_family
  db_parameters                   = var.db_parameters
  aurora_instance_count           = var.aurora_instance_count
  vpc_id                          = module.vpc.vpc_id
  private_subnet_ids              = module.vpc.private_subnet_ids
  eks_node_sg_id                  = module.eks.node_security_group_id
  tags                            = var.tags

  depends_on = [module.eks]
}

module "external_secrets" {
  source            = "./modules/external_secrets"
  project_name      = var.project_name
  aws_region        = var.aws_region
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  secret_arns = [
    module.secrets.django_secret_arn,
    module.secrets.grafana_secret_arn,
    module.rds.master_user_secret_arn,
  ]
  tags = var.tags

  depends_on = [module.eks, module.rds]
}

module "jenkins" {
  source             = "./modules/jenkins"
  project_name       = var.project_name
  namespace          = "jenkins"
  ecr_repository_url = module.ecr.repository_url
  ecr_repository_arn = module.ecr.repository_arn
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_url  = module.eks.oidc_provider_url
  tags               = var.tags

  depends_on = [module.eks, kubernetes_storage_class_v1.gp3]
}

module "argo_cd" {
  source             = "./modules/argo_cd"
  namespace          = "argocd"
  repo_url           = var.argocd_repo_url
  target_revision    = "main"
  ecr_repository_url = module.ecr.repository_url
  rds_endpoint       = module.rds.endpoint
  rds_port           = module.rds.port
  rds_secret_arn     = module.rds.master_user_secret_arn
  django_secret_arn  = module.secrets.django_secret_arn

  depends_on = [
    module.eks,
    module.external_secrets,
  ]
}

module "monitoring" {
  source             = "./modules/monitoring"
  namespace          = "monitoring"
  grafana_secret_arn = module.secrets.grafana_secret_arn
  tags               = var.tags

  depends_on = [
    module.eks,
    module.external_secrets,
    kubernetes_storage_class_v1.gp3,
  ]
}
