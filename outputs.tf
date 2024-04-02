output "vpc_id" {
  value       = module.simetrik_network.vpc_id
  description = "Id of generated VPC"
}

output "vpc_privsub" {
  value       = module.simetrik_network.vpc_privsub
  description = "Range of set private subnets"
}