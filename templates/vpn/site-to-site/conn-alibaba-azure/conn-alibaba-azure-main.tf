# Terraform module for Alibaba and Azure VPN Site-to-Site connection
module "conn_alibaba_azure" {
  source = "./modules/conn-alibaba-azure"

  # Input variables
  name_prefix   = var.vpn_config.terrarium_id
  shared_secret = var.vpn_config.shared_secret

  # Azure configuration
  azure_region                     = var.vpn_config.azure.region
  azure_resource_group_name        = var.vpn_config.azure.resource_group_name
  azure_bgp_asn                    = var.vpn_config.azure.bgp_asn
  azure_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw.id
  azure_public_ip_addresses        = azurerm_public_ip.pub_ip[*].ip_address
  azure_apipa_cidrs                = var.vpn_config.azure.bgp_peering_cidrs.to_alibaba
  azure_virtual_network_cidr       = data.azurerm_virtual_network.existing.address_space[0]

  # Alibaba configuration
  alibaba_vpc_id                  = var.vpn_config.alibaba.vpc_id
  alibaba_vpn_gateway_id          = alicloud_vpn_gateway.main.id
  alibaba_vpn_gateway_internet_ip = alicloud_vpn_gateway.main.internet_ip
  alibaba_bgp_asn                 = var.vpn_config.alibaba.bgp_asn
}
