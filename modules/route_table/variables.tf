variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = map(string) }
variable "internet_gateway_id" {
  type    = string
  default = null
}
variable "nat_gateway_id" {
  type    = string
  default = null
}
