terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.29.0"
    }
  }
  backend "s3" {
    encrypt = true
  }
  required_version = ">= 1.2.6"
}
