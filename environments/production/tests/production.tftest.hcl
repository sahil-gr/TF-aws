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
    condition     = length(module.nat_gateway) == 1 && length(module.private_route_table) == 2 && contains(keys(module.nat_gateway), var.availability_zones[0])
    error_message = "Require one shared NAT gateway in the first AZ and a private route table per AZ."
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
