# Fetch a route table from AWS
data "aws_route_table" "imported" {
  subnet_id = var.aws-subnet-id
}

import {
  to = aws_route_table.imported_route_table
  id = data.aws_route_table.imported.id
}

# This is an imported AWS Route Table.
# Thus, it must NOT be destroyed by Tofu.
# Run `tofu state rm aws_route_table.imported_route_table` to remove it from the state file.
resource "aws_route_table" "imported_route_table" {
  tags = data.aws_route_table.imported.tags

  vpc_id           = var.aws-vpc-id
  propagating_vgws = [aws_vpn_gateway.vpn_gw.id]

  lifecycle {
    prevent_destroy = true
  }
}
