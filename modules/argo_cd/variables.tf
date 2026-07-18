variable "namespace" {
  type    = string
  default = "argocd"
}

variable "repo_url" {
  description = "Git repository Argo CD tracks for application manifests"
  type        = string
}

variable "target_revision" {
  type    = string
  default = "main"
}

variable "ecr_repository_url" {
  type = string
}

variable "rds_endpoint" {
  type      = string
  sensitive = true
}

variable "rds_port" {
  type = number
}

variable "rds_secret_arn" {
  type = string
}

variable "django_secret_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
