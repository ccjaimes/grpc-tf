locals {
  tags = {
    Project   = "Simetrik-test"
    CreatedOn = timestamp()
    Env       = terraform.workspace
  }
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
