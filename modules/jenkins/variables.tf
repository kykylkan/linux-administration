variable "namespace" {
  type    = string
  default = "jenkins"
}

variable "project_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "ecr_repository_url" {
  description = "ECR repository URL exposed to Jenkins pipelines"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN Jenkins may push images to"
  type        = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}
