variable "namespace" {
  type    = string
  default = "external-secrets"
}

variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "secret_arns" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
