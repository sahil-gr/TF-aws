project        = "nginx"
region         = "us-west-2"
aws_account_id     = "633890776902"
availability_zones = ["us-west-2a", "us-west-2b"]
vpc_cidr              = "10.20.0.0/16"

# Automatically fetch AWS's latest standard AL2023 x86_64 AMI in this region.
ami_id           = null
instance_type    = "t3.small"
min_size         = 2
desired_capacity = 2
max_size         = 4

allowed_client_cidrs = ["0.0.0.0/0"]
alb_deletion_protection =true

# Optional SNS topics with confirmed subscriptions for alarm notifications.
alarm_topic_arns = []

tags = {
  Owner      = "platform-team"
  CostCenter = "DevOps"
}
