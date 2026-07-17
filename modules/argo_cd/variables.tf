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

variable "tags" {
  type    = map(string)
  default = {}
}
