# Azure module
module "azure" {
  source = "./modules/azure"

  # Input variables
  name_prefix          = var.vpn_config.terrarium_id
  region               = var.vpn_config.target_csp.azure.region
  resource_group_name  = var.vpn_config.target_csp.azure.resource_group_name
  virtual_network_name = var.vpn_config.target_csp.azure.virtual_network_name
  gateway_subnet_cidr  = var.vpn_config.target_csp.azure.gateway_subnet_cidr
  vpn_sku              = var.vpn_config.target_csp.azure.vpn_sku
  bgp_asn              = var.vpn_config.target_csp.azure.bgp_asn

  # AWS resource
  aws_vpn_gateway_id = aws_vpn_gateway.vpn_gw.id

}
