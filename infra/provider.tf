terraform {
  backend "s3" {
    bucket  = "servian-tech-app-jesse-1656812402"
    key     = "Terraform/State/ServianTechApp"
    region  = "ap-southeast-2"
    encrypt = "true"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.21.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.3.2"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}
