
### IAM roles for CodeBuild
# Policy declaration to allow CodeBuild projects to assume a role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Link a new role with the previous policy
resource "aws_iam_role" "codebuildrole" {
  name               = "codebuildrole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Policy declaration to push images to ECR
resource "aws_iam_policy" "build-ecr" {
  name = "Build-ECR"
  policy = jsonencode({
    "Statement" : [
      {
        "Action" : [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
    ],
    "Version" : "2012-10-17"
  })
}

# Policy declaration to interact with EKS cluster
resource "aws_iam_policy" "eks-access" {
  name = "EKS-access"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "eks:DescribeCluster"
        ],
        "Resource" : "*"
      }
    ]
  })
}


# Link codebuildrole with created ECR policy
resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.codebuildrole.name
  policy_arn = aws_iam_policy.build-ecr.arn
}

# Link codebuildrole with created EKS policy
resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.codebuildrole.name
  policy_arn = aws_iam_policy.eks-access.arn
}

# Policy definition to export logs to CloudWatch
data "aws_iam_policy_document" "permissions" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

# Link codebuildrole with created Cloudwatch policy
resource "aws_iam_role_policy" "permissions_policy" {
  role   = aws_iam_role.codebuildrole.name
  policy = data.aws_iam_policy_document.permissions.json
}

###################################################################################################
###################################################################################################

### Creating ECR Registry
resource "aws_ecr_repository" "Simetrik-ecr" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

###################################################################################################
###################################################################################################

data "aws_caller_identity" "current" {}

### CodeBuild resource
resource "aws_codebuild_project" "cicd" {
  name         = var.codebuild_project_name
  service_role = aws_iam_role.codebuildrole.arn

  # Specs of the base image the pipeline will be executed on, as well as important env variables
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "us-east-2"
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_URL"
      value = aws_ecr_repository.Simetrik-ecr.repository_url
    }
  }

  # Source of the buildspec.yml file with pipeline steps
  source {
    type            = "GITHUB"
    location        = var.github_repo
    git_clone_depth = 1
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  # Repo branch CodeBuild will build from
  source_version = "main"
}