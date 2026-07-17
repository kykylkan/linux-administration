terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "devops-final-project-tfstate"
    key            = "final-project/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "devops-final-project-tf-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
