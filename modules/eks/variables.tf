variable "project_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "cluster_admin_principal_arn" {
  description = "IAM principal that Terraform grants cluster-admin access"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "node_instance_types" {
  type = list(string)
}

variable "node_desired_size" {
  type = number
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "tags" {
  type    = map(string)
  default = {}
}
