variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "tags" {
  type    = map(string)
  default = {}
}
