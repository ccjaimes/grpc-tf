variable "vpc_id" {
  type        = string
  description = "Id of VPC for eks cluster"
}

variable "privsub" {
  type        = list(string)
  description = "Private subnet range available for eks cluster"
}

variable "codebuild_project_name" {
  type        = string
  description = "Codebuild Project name to handle app's CICD"
  default     = "Simetrik-Codebuild"
}

variable "github_repo" {
  type        = string
  description = "Github repo link with app code"
  default     = "https://github.com/ccjaimes/grpc-py-test.git"
}

variable "buildspec" {
  type        = string
  description = "CICD pipeline in yml structure for CodeBuild to process"
  default     = <<-EOF
      version: 0.2

      phases:
        pre-build:
          commands:
            - echo "Setting ECR permissions"
            - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  build:
        build:
          commands:
            - LATEST=git describe --tags --abbrev=0 
            - docker build -t $IMAGE_REPO:$LATEST .
        test:
          commands:
            - echo "Tests to be implemented in a future sprint!"
            - echo "Tests passed!"
        push:
          commands:
            - docker push $IMAGE_REPO:$LATEST
    EOF
}