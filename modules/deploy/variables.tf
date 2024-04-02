variable "github_repo" {
  type        = string
  description = "Github repo link with app code"
  default     = "https://github.com/ccjaimes/grpc-py-test.git"
}


variable "codebuild_project_name" {
  type        = string
  description = "Codebuild Project name to handle app's CICD"
  default     = "Simetrik-Codebuild"
}

variable "ecr_repo_name" {
  type        = string
  description = "ECR private repository name"
  default     = "simetrikgrpcrepo"
}