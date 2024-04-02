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

### Network module reference
module "simetrik_network" {
  source          = "./modules/network"
  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.0.0/24", "10.0.32.0/24"]
  public_subnets  = ["10.0.64.0/24", "10.0.96.0/24"]
}

### EKS & Load Balancer module reference
module "simetrik_eks" {
  source       = "./modules/eks"
  vpc_id       = module.simetrik_network.vpc_id
  privsub      = module.simetrik_network.vpc_privsub
  vpc_owner_id = module.simetrik_network.vpc_owner_id
}

### ECR & CodeBuild module reference
module "simetrik_deploy" {
  source = "./modules/deploy"
}
