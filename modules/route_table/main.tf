resource "aws_route_table" "this" {
  vpc_id = var.vpc_id
  tags   = { Name = var.name }
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
  nat_gateway_id         = var.nat_gateway_id

  lifecycle {
    precondition {
      condition     = (var.internet_gateway_id != null) != (var.nat_gateway_id != null)
      error_message = "Provide exactly one Internet gateway or NAT gateway."
    }
  }
}

resource "aws_route_table_association" "this" {
  for_each       = var.subnet_ids
  subnet_id      = each.value
  route_table_id = aws_route_table.this.id
}
