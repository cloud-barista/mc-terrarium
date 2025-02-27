resource "aws_vpn_gateway" "vpn_gw" {
  tags = {
    Name = "${local.name_prefix}-vpn-gw"
  }
  vpc_id = var.vpn_config.aws.vpc_id
}
