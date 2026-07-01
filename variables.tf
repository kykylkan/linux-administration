variable "aws_region" {
  description = "AWS регіон для розгортання інфраструктури"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Назва проєкту, використовується як префікс для ресурсів"
  type        = string
  default     = "lesson-8-9"
}

variable "environment" {
  description = "Оточення (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR блок для VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR блоки для публічних підмереж"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR блоки для приватних підмереж"
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "eks_cluster_version" {
  description = "Версія Kubernetes для EKS"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "Типи інстансів для EKS ноди"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_desired_size" {
  type    = number
  default = 2
}

variable "eks_min_size" {
  type    = number
  default = 1
}

variable "eks_max_size" {
  type    = number
  default = 3
}

variable "ecr_repository_name" {
  description = "Назва ECR репозиторію для Django застосунку"
  type        = string
  default     = "django-app"
}

variable "git_repo_url" {
  description = "URL git-репозиторію з Helm chart, за яким слідкує Argo CD"
  type        = string
  default     = "https://github.com/<your-account>/lesson-8-9-gitops.git"
}

variable "git_repo_revision" {
  description = "Гілка/revision в git-репозиторії для Argo CD Application"
  type        = string
  default     = "main"
}

variable "django_app_chart_path" {
  description = "Шлях до Helm chart django-app всередині git-репозиторію"
  type        = string
  default     = "charts/django-app"
}

variable "argocd_namespace" {
  type    = string
  default = "argocd"
}

variable "jenkins_namespace" {
  type    = string
  default = "jenkins"
}
