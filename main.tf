locals {
  tags = {
    Project   = "Simetrik-test"
    CreatedOn = timestamp()
    Env       = terraform.workspace
  }
}

provider "aws" {
  region = "us-east-2"
}

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
      version = ">= 5.3"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }

  required_version = ">= 1.0"
}

module "simetrik_network" {
  source          = "./modules/network"
  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]
}

module "simetrik_eks" {
  source  = "./modules/eks"
  vpc_id  = module.simetrik_network.vpc_id
  privsub = module.simetrik_network.vpc_privsub
}