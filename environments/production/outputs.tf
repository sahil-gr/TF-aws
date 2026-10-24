output "selected_ami_id" {
  description = "Amazon Linux 2023 AMI selected for the EC2 launch template."
  value       = local.selected_ami_id
}

output "vpc_id" {
  description = "Application VPC ID."
  value       = module.vpc.id
}
output "public_subnet_ids" {
  description = "Public ALB subnets, keyed by availability zone; the first AZ also hosts the shared NAT gateway."
  value       = { for az, subnet in module.public_subnet : az => subnet.id }
}
output "private_subnet_ids" {
  description = "EC2 subnets, keyed by availability zone."
  value       = { for az, subnet in module.private_subnet : az => subnet.id }
}
output "alb_dns_name" {
  description = "AWS-provided public ALB hostname, accessible over HTTP."
  value       = module.load_balancer.dns_name
}
output "alb_url" {
  description = "Open this URL to access Nginx through the public ALB."
  value       = "http://${module.load_balancer.dns_name}"
}
output "autoscaling_group_name" {
  description = "Group managing the private Nginx EC2 instances."
  value       = module.ec2.autoscaling_group_name
}
output "alb_log_bucket" {
  description = "Private S3 bucket retaining ALB access logs."
  value       = module.logging.alb_bucket_id
}
