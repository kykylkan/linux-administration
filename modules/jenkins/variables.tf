variable "namespace" {
  type    = string
  default = "jenkins"
}

variable "tags" {
  type    = map(string)
  default = {}
}
