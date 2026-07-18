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

output "rds_reader_endpoint" {
  value     = module.rds.reader_endpoint
  sensitive = true
}

output "rds_port" {
  value = module.rds.port
}

output "rds_master_user_secret_arn" {
  value = module.rds.master_user_secret_arn
}

output "jenkins_ecr_push_role_arn" {
  value = module.jenkins.ecr_push_role_arn
}

output "external_secrets_role_arn" {
  value = module.external_secrets.role_arn
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
