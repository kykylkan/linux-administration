variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to distribute subnets across"
  type        = list(string)
}

variable "vpc_name" {
  description = "Name tag applied to VPC and related resources"
  type        = string
  default     = "main-vpc"
}
