provider "aws" {
  region = "us-east-2"
}

### Terraform Backend Setup & external providers' required versions
terraform {
  backend "s3" {
    bucket         = "simetrik-tfbackend"
    key            = "state/terraform.state"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "simetrik-tflockid"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.29.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }
  }

  required_version = ">= 1.0"
}