resource "aws_vpn_gateway" "vpn_gw" {
  tags = {
    Name = "${local.name_prefix}-vpn-gw"
  }
  vpc_id = var.vpn_config.aws.vpc_id

  # The Amazon side ASN is the BGP ASN for the AWS side of the VPN connection.
  # This value seems to be assigned to the AWS side BGP ASN of the VPN connection.
  # The default value is 64512, which is the private ASN range (64512-65535).
  # If you want to use a custom ASN, you can uncomment the line below and set it to your desired value.
  # Default: 64512
  amazon_side_asn = var.vpn_config.aws.bgp_asn
}

# Fetching AWS VPC and subnet information
data "aws_vpc" "existing" {
  id = var.vpn_config.aws.vpc_id
}

data "aws_subnets" "fetched" {
  filter {
    name   = "vpc-id"
    values = [var.vpn_config.aws.vpc_id]
  }
}

# Get subnet details for all subnets
data "aws_subnet" "details" {
  for_each = toset(data.aws_subnets.fetched.ids)
  id       = each.value
}

locals {
  aws_subnet_cidrs = [for subnet in data.aws_subnet.details : subnet.cidr_block]
}

# Get Route Table associated with the subnet
data "aws_route_table" "selected" {
  subnet_id = var.vpn_config.aws.subnet_id
}

# Enable Route Propagation
resource "aws_vpn_gateway_route_propagation" "main" {
  vpn_gateway_id = aws_vpn_gateway.vpn_gw.id
  route_table_id = data.aws_route_table.selected.id
}
