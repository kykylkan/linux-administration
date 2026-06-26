aws_region          = "eu-central-1"
environment         = "production"
state_bucket_name   = "django-app-terraform-state"
state_lock_table    = "terraform-state-lock"

vpc_cidr            = "10.0.0.0/16"
public_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets     = ["10.0.11.0/24", "10.0.12.0/24"]
availability_zones  = ["eu-central-1a", "eu-central-1b"]

ecr_repository_name = "django-app"

cluster_name        = "django-cluster"
cluster_version     = "1.29"
node_group_name     = "django-nodes"
instance_types      = ["t3.medium"]
desired_size        = 2
min_size            = 1
max_size            = 4
