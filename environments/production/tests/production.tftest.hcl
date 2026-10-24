mock_provider "aws" {}

variables {
  aws_account_id = "123456789012"
  ami_id         = "ami-0123456789abcdef0"
}

run "production_topology" {
  command = plan
  assert {
    condition     = length(module.public_subnet) == 2 && length(module.private_subnet) == 2
    error_message = "Production requires public and private subnets in two AZs."
  }
  assert {
    condition     = length(module.nat_gateway) == 2 && length(module.private_route_table) == 2
    error_message = "Every AZ must have its own NAT gateway and private route table."
  }
}

run "reject_single_az" {
  command = plan
  variables { availability_zones = ["ap-south-1a"] }
  expect_failures = [var.availability_zones]
}

run "reject_invalid_client_cidr" {
  command = plan
  variables { allowed_client_cidrs = ["invalid-cidr"] }
  expect_failures = [var.allowed_client_cidrs]
}
