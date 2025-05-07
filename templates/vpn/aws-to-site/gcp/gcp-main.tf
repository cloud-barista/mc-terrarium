# GCP module
module "gcp" {
  source = "./modules/gcp"

  # Input variables
  name_prefix      = var.vpn_config.terrarium_id
  vpc_network_name = var.vpn_config.target_csp.gcp.vpc_network_name
  bgp_asn          = var.vpn_config.target_csp.gcp.bgp_asn
  # region              = var.vpn_config.target_csp.gcp.region

  # AWS resource
  aws_vpn_gateway_id = aws_vpn_gateway.vpn_gw.id

}
