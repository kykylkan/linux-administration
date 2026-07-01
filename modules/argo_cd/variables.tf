variable "namespace" {
  type = string
}

variable "project_name" {
  type = string
}

variable "git_repo_url" {
  description = "URL git-репозиторію з Helm chart, за яким слідкує Argo CD"
  type        = string
}

variable "git_repo_revision" {
  type    = string
  default = "main"
}

variable "chart_path" {
  description = "Шлях до Helm chart всередині git-репозиторію"
  type        = string
}

variable "target_namespace" {
  description = "Namespace в кластері, куди Argo CD деплоїть застосунок"
  type        = string
  default     = "django-app"
}

variable "chart_version" {
  description = "Версія Helm chart argo/argo-cd"
  type        = string
  default     = "7.3.11"
}
