variable "vpc_id" {
  type        = string
  description = "Id of VPC for eks cluster"
}

variable "privsub" {
  type        = list(string)
  description = "Private subnet range available for eks cluster"
}

variable "vpc_owner_id" {
  type        = string
  description = "ID of the owner user of the VPC"
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "grpc-test-eks"
}

variable "k8s_version" {
  type        = string
  description = "The Kubernetes version our EKS cluster will use"
  default     = "1.29"
}