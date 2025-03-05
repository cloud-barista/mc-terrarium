resource "aws_vpn_gateway" "vpn_gw" {
  tags = {
    Name = "${local.name_prefix}-vpn-gw"
  }
  vpc_id = var.vpn_config.aws.vpc_id
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
