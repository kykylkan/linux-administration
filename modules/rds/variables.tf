variable "project_name" {
  type = string
}

variable "use_aurora" {
  type    = bool
  default = false
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "instance_class" {
  type = string
}

variable "postgres_engine_version" {
  type = string
}

variable "aurora_engine_version" {
  type = string
}

variable "postgres_parameter_group_family" {
  type = string
}

variable "aurora_parameter_group_family" {
  type = string
}

variable "db_parameters" {
  type    = map(string)
  default = {}
}

variable "aurora_instance_count" {
  type    = number
  default = 2
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "eks_node_sg_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
