# Import a route table from the AWS provider
import {
  to = aws_route_table.my-imported-aws-route-table
  id = data.aws_route_table.imported.id
}

# This is an imported AWS Route Table.
# Thus, it must NOT be destroyed by Tofu.
# Run `tofu state rm aws_route_table.my-imported-aws-route-table` to remove it from the state file.
resource "aws_route_table" "my-imported-aws-route-table" {
  tags = data.aws_route_table.imported.tags
  
  vpc_id = var.my-imported-aws-vpc-id
  propagating_vgws = [aws_vpn_gateway.my-aws-vpn-gateway.id]

  lifecycle {
    prevent_destroy = true
  }
}
