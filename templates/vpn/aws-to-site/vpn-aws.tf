
resource "aws_vpn_gateway" "vpn_gw" {
  tags = {
    Name = "${local.name_prefix}-vpn-gw"
  }
  vpc_id = var.vpn_config.aws.vpc_id
}

data "aws_vpc" "selected" {
  count = local.is_alibaba ? 1 : 0

  id = var.vpn_config.aws.vpc_id
}
