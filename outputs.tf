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

output "jenkins_namespace" {
  value = module.jenkins.namespace
}

output "jenkins_admin_password_command" {
  description = "Команда для отримання пароля адміністратора Jenkins"
  value       = module.jenkins.admin_password_command
}

output "argocd_namespace" {
  value = module.argo_cd.namespace
}

output "argocd_admin_password_command" {
  description = "Команда для отримання початкового пароля адміністратора Argo CD"
  value       = module.argo_cd.admin_password_command
}

output "s3_backend_bucket" {
  value = module.s3_backend.bucket_name
}

output "s3_backend_dynamodb_table" {
  value = module.s3_backend.dynamodb_table_name
}
