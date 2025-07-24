data "aws_route_table" "imported" {
  subnet_id = var.vpn_config.aws.subnet_id
}

import {
  to = aws_route_table.imported_route_table
  id = data.aws_route_table.imported.id
}

resource "aws_route_table" "imported_route_table" {
  tags = data.aws_route_table.imported.tags

  vpc_id           = var.vpn_config.aws.vpc_id
  propagating_vgws = [aws_vpn_gateway.vpn_gw.id]

  lifecycle {
    prevent_destroy = true
  }
}
