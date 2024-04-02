### EKS Cluster Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.k8s_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # These are imported from the Network module
  vpc_id     = var.vpc_id
  subnet_ids = var.privsub

  enable_irsa = true

  eks_managed_node_group_defaults = {
    disk_size = 50
  }

  # This block defines the specifications of the instances hosting our cluster
  eks_managed_node_groups = {
    general = {
      desired_size = 1
      min_size     = 1
      max_size     = 3

      labels = {
        role = "general"
      }

      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
    }
  }

  # This block links the permissions and roles from AWS with the internal K8s Auth ConfigMap
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = module.eks_admins_iam_role.iam_role_arn
      username = module.eks_admins_iam_role.iam_role_name
      groups   = ["system:masters"]
    },
  ]

  # This block creates a network rule for an open port to enable communication between the control plane and AWS LBC
  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                       = "ingress"
      protocol                   = "tcp"
      from_port                  = 9443
      to_port                    = 9443
      source_node_security_group = true
      description                = "Allow access from control plane to webhook port of AWS load balancer controller"
    }
  }

  tags = {
    Environment = "staging"
  }
}

###################################################################################################
###################################################################################################

### Policy & Role creations to authenticate with EKS
# Policy definition to authenticate with K8s internally (Use kubectl)
module "allow_eks_access_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  name          = "allow-eks-access"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Role definition that holds the previous policy and can be assigned to users, groups and Service Accounts
module "eks_admins_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.3.1"

  role_name         = "eks-admin"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${var.vpc_owner_id}:root"
  ]
}

# Policy definition to allow users to assume the role previously created
module "allow_assume_eks_admins_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  name          = "allow-assume-eks-admin-iam-role"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = module.eks_admins_iam_role.iam_role_arn
      },
    ]
  })
}

# Create a group with the policy to assume K8s role to its members
module "eks_admins_iam_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.3.1"

  name                              = "eks-admin"
  attach_iam_self_management_policy = false
  create_group                      = true
  custom_group_policy_arns          = [module.allow_assume_eks_admins_iam_policy.arn]
}

data "aws_eks_cluster" "default" {
  depends_on = [ module.eks.cluster_name ]
  name = module.eks.cluster_name
}

###################################################################################################
###################################################################################################

### Load Balancer & IAM Access roles

# Define the Service Account role for the load balancer
module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.1"

  role_name = "aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# Implement helm's Load Balancer Controller integration for AWS
resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.5.0"

  set {
    name  = "replicaCount"
    value = 1
  }

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.default.name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }
}
