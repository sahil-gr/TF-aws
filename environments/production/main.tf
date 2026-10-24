locals {
  name = "${var.project}-prod"
  tags = merge(var.tags, {
    Project     = var.project
    Environment = "production"
    ManagedBy   = "Terraform"
  })
  zones = { for index, az in var.availability_zones : az => index }
}

data "aws_ssm_parameter" "al2023" {
  count           = var.ami_id == null ? 1 : 0
  name            = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  with_decryption = false
}

locals {
  # This AWS public parameter contains a public AMI ID, not a secret.
  selected_ami_id = var.ami_id != null ? var.ami_id : nonsensitive(data.aws_ssm_parameter.al2023[0].value)
}

module "vpc" {
  source     = "../../modules/vpc"
  name       = local.name
  cidr_block = var.vpc_cidr
}

module "public_subnet" {
  for_each          = local.zones
  source            = "../../modules/subnet"
  name              = "${local.name}-public-${each.key}"
  vpc_id            = module.vpc.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value)
  tier              = "public"
}

module "private_subnet" {
  for_each          = local.zones
  source            = "../../modules/subnet"
  name              = "${local.name}-private-${each.key}"
  vpc_id            = module.vpc.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value + 16)
  tier              = "private"
}

module "internet_gateway" {
  source = "../../modules/internet_gateway"
  name   = "${local.name}-igw"
  vpc_id = module.vpc.id
}

module "public_route_table" {
  source              = "../../modules/route_table"
  name                = "${local.name}-public"
  vpc_id              = module.vpc.id
  subnet_ids          = { for az, subnet in module.public_subnet : az => subnet.id }
  internet_gateway_id = module.internet_gateway.id
}

module "nat_gateway" {
  # Keep the first AZ's existing module address when consolidating NAT gateways.
  for_each   = { (var.availability_zones[0]) = 0 }
  source     = "../../modules/nat_gateway"
  name       = "${local.name}-nat-${each.key}"
  subnet_id  = module.public_subnet[each.key].id
  depends_on = [module.internet_gateway, module.public_route_table]
}

module "private_route_table" {
  for_each       = local.zones
  source         = "../../modules/route_table"
  name           = "${local.name}-private-${each.key}"
  vpc_id         = module.vpc.id
  subnet_ids     = { private = module.private_subnet[each.key].id }
  nat_gateway_id = module.nat_gateway[var.availability_zones[0]].id
}

module "security_groups" {
  source        = "../../modules/security_groups"
  name          = local.name
  vpc_id        = module.vpc.id
  allowed_cidrs = var.allowed_client_cidrs
}

module "logging" {
  source = "../../modules/logging"
  name   = local.name
  vpc_id = module.vpc.id
  region = var.region
}

module "iam" {
  source        = "../../modules/iam"
  name          = local.name
  log_group_arn = module.logging.web_log_group_arn
}

module "load_balancer" {
  source              = "../../modules/load_balancer"
  name                = local.name
  vpc_id              = module.vpc.id
  public_subnet_ids   = [for subnet in module.public_subnet : subnet.id]
  security_group_id   = module.security_groups.alb_id
  access_log_bucket   = module.logging.alb_bucket_id
  deletion_protection = var.alb_deletion_protection
  alarm_topic_arns    = var.alarm_topic_arns
  depends_on          = [module.public_route_table]
}

module "ec2" {
  source                = "../../modules/ec2"
  name                  = local.name
  region                = var.region
  ami_id                = local.selected_ami_id
  instance_type         = var.instance_type
  private_subnet_ids    = [for subnet in module.private_subnet : subnet.id]
  security_group_id     = module.security_groups.web_id
  instance_profile_name = module.iam.instance_profile_name
  target_group_arn      = module.load_balancer.target_group_arn
  log_group_name        = module.logging.web_log_group_name
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = var.desired_capacity
  tags                  = local.tags
  depends_on            = [module.private_route_table]
}
