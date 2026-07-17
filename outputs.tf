output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "rds_endpoint" {
  value     = module.rds.endpoint
  sensitive = true
}

output "s3_state_bucket" {
  value = module.s3_backend.bucket_name
}

output "dynamodb_lock_table" {
  value = module.s3_backend.dynamodb_table_name
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
