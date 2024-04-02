### This module will create our VPC with required subnets and NAT Gateway
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.7.0"

  name = var.vpc_name
  cidr = var.cidr

  azs             = var.av_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "staging"
  }
}