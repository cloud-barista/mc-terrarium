# Tencent module
module "tencent" {
  source = "./modules/tencent"

  # Input variables
  name_prefix = var.vpn_config.terrarium_id
  vpc_id      = var.vpn_config.target_csp.tencent.vpc_id
  # bgp_asn     = var.vpn_config.target_csp.tencent.bgp_asn

  # AWS resource
  aws_vpn_gateway_id = aws_vpn_gateway.vpn_gw.id
  aws_vpc_cidr_block = data.aws_vpc.existing.cidr_block
}
