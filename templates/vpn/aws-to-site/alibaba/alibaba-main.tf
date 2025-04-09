# Alibaba module
module "alibaba" {
  source = "./modules/alibaba"

  # Input variables
  name_prefix  = var.vpn_config.terrarium_id
  vpc_id       = var.vpn_config.target_csp.alibaba.vpc_id
  vswitch_id_1 = var.vpn_config.target_csp.alibaba.vswitch_id_1
  vswitch_id_2 = var.vpn_config.target_csp.alibaba.vswitch_id_2
  bgp_asn      = var.vpn_config.target_csp.alibaba.bgp_asn

  # AWS resource
  aws_vpn_gateway_id = aws_vpn_gateway.vpn_gw.id
  aws_vpc_cidr_block = data.aws_vpc.existing.cidr_block
}
