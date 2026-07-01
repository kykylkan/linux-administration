variable "namespace" {
  type = string
}

variable "project_name" {
  type = string
}

variable "ecr_repo_url" {
  description = "URL ECR репозиторію, куди Jenkins буде пушити образи"
  type        = string
}

variable "aws_region" {
  type = string
}

variable "chart_version" {
  description = "Версія Helm chart jenkinsci/jenkins"
  type        = string
  default     = "5.7.10"
}
