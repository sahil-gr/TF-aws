variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "access_log_bucket" { type = string }
variable "deletion_protection" { type = bool }
variable "alarm_topic_arns" { type = list(string) }
