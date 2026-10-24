variable "name" { type = string }
variable "vpc_id" { type = string }
variable "region" { type = string }
variable "retention_days" {
  type    = number
  default = 90
}
