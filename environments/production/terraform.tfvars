project            = "nginx"
region             = "ap-south-1"
# Replace with your actual 12-digit AWS account ID.
aws_account_id     = "123456789012"
availability_zones = ["ap-south-1a", "ap-south-1b"]
vpc_cidr           = "10.20.0.0/16"

# Replace before deploying: approved AL2023 x86_64 AMI in ap-south-1.
ami_id           = "REPLACE-WITH-YOUR-AMI-ID"
instance_type    = "t3.small"
min_size         = 2
desired_capacity = 2
max_size         = 4

allowed_client_cidrs     = ["0.0.0.0/0"]
alb_deletion_protection = true
# Optional SNS topics with confirmed subscriptions for alarm notifications.
alarm_topic_arns = []

tags = {
  Owner      = "platform-team"
  CostCenter = "REPLACE-ME"
}
