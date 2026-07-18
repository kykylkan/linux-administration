variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "grafana_secret_arn" {
  type = string
}
