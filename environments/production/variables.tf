variable "project" {
  description = "Short resource prefix; keeps ALB and IAM names within AWS limits."
  type        = string
  default     = "nginx"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}[a-z0-9]$", var.project))
    error_message = "Use 3-20 lowercase letters, digits or hyphens; start with a letter and end with a letter or digit."
  }
}

variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-west-2"
}

variable "aws_account_id" {
  description = "Expected deployment account; provider rejects other accounts."
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "Provide a 12-digit AWS account ID."
  }
}

variable "availability_zones" {
  description = "Two or three standard AZs in region. Keep their order stable: indices determine subnet CIDRs."
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
  validation {
    condition = (
      length(var.availability_zones) >= 2 && length(var.availability_zones) <= 3 &&
      length(distinct(var.availability_zones)) == length(var.availability_zones) &&
      alltrue([for az in var.availability_zones : can(regex("^${var.region}[a-z]$", az))])
    )
    error_message = "Provide 2-3 distinct standard AZs in the configured region."
  }
}

variable "vpc_cidr" {
  description = "Canonical IPv4 /16; derived public /24s start at index 0 and private /24s at index 16."
  type        = string
  default     = "10.20.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && can(regex("/16$", var.vpc_cidr)) && try(cidrhost(var.vpc_cidr, 0) == split("/", var.vpc_cidr)[0], false)
    error_message = "Provide a canonical IPv4 /16, for example 10.20.0.0/16."
  }
}

variable "allowed_client_cidrs" {
  description = "IPv4 client CIDRs allowed to reach ALB HTTP port 80. Public by default."
  type        = list(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition     = length(var.allowed_client_cidrs) > 0 && alltrue([for cidr in var.allowed_client_cidrs : can(cidrnetmask(cidr))])
    error_message = "Provide at least one valid IPv4 CIDR."
  }
}

variable "ami_id" {
  description = "Optional Amazon Linux 2023 x86_64 AMI override. Null reads AWS's latest standard AMI from the regional public SSM parameter."
  type        = string
  default     = null
  validation {
    condition     = var.ami_id == null ? true : can(regex("^ami-[0-9a-f]{17}$", var.ami_id))
    error_message = "Provide an AMI ID or null."
  }
}

variable "instance_type" {
  description = "x86_64 instance type compatible with the selected AMI."
  type        = string
  default     = "t3.small"
}

variable "min_size" {
  description = "Minimum web instances; at least two for multi-AZ availability."
  type        = number
  default     = 2
  validation {
    condition     = var.min_size >= 2 && floor(var.min_size) == var.min_size
    error_message = "min_size must be an integer >= 2."
  }
}

variable "max_size" {
  description = "Upper bound for CPU-driven scaling."
  type        = number
  default     = 4
  validation {
    condition     = var.max_size >= var.desired_capacity && floor(var.max_size) == var.max_size
    error_message = "max_size must be an integer >= desired_capacity."
  }
}

variable "desired_capacity" {
  description = "Initial capacity; subsequently owned by autoscaling, not reset on each apply."
  type        = number
  default     = 2
  validation {
    condition     = var.desired_capacity >= var.min_size && floor(var.desired_capacity) == var.desired_capacity
    error_message = "desired_capacity must be an integer >= min_size."
  }
}

variable "alb_deletion_protection" {
  description = "Keep enabled in production; explicitly disable and apply before teardown."
  type        = bool
  default     = true
}

variable "alarm_topic_arns" {
  description = "Existing regional SNS topics with confirmed subscriptions for unhealthy-target notifications."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags, such as Owner and CostCenter."
  type        = map(string)
  default     = {}
}
