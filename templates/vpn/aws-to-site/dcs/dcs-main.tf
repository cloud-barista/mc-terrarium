# DCS module
module "dcs" {
  source = "./modules/dcs"

  # Input variables
  name_prefix = var.vpn_config.terrarium_id
  router_id   = var.vpn_config.target_csp.dcs.router_id
  subnet_id   = var.vpn_config.target_csp.dcs.subnet_id
  bgp_asn     = try(var.vpn_config.target_csp.dcs.bgp_asn, "65000")

  # AWS resource
  aws_vpn_gateway_id = aws_vpn_gateway.vpn_gw.id
  aws_vpc_cidr       = data.aws_vpc.existing.cidr_block
}
