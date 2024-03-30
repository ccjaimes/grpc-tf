output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "Id of generated VPC"
}

output "vpc_privsub" {
  value       = module.vpc.private_subnets
  description = "Range of set private subnets"
}