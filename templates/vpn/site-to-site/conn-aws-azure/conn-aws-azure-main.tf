# Terraform module for AWS and Azure VPN Site-to-Site connection
module "conn_aws_azure" {
  source = "./modules/conn-aws-azure"

  # Input variables
  name_prefix               = var.vpn_config.terrarium_id
  azure_region              = var.vpn_config.azure.region
  azure_resource_group_name = var.vpn_config.azure.resource_group_name
  azure_bgp_asn             = var.vpn_config.azure.bgp_asn
  azure_apipa_cidrs         = var.vpn_config.azure.bgp_peering_cidrs.to_aws

  # AWS resources info, created 
  aws_vpn_gateway_id = aws_vpn_gateway.vpn_gw.id

  # Azure resources info, created
  azure_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw.id
  azure_public_ip_addresses        = azurerm_public_ip.pub_ip[*].ip_address
}
