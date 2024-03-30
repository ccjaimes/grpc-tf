variable "vpc_name" {
  type        = string
  description = "Name of the VPC resource"
  default     = "main"
}

variable "av_zones" {
  type        = list(any)
  description = "Availability Zones the VPC will cover"
  default     = ["us-east-2a", "us-east-2b"]
}

variable "cidr" {
  type        = string
  description = "CIDR block definition"
}

variable "private_subnets" {
  type        = list(any)
  description = "Range of the private subnet in the VPC"
}

variable "public_subnets" {
  type        = list(any)
  description = "Range of the public subnet in the VPC"
}