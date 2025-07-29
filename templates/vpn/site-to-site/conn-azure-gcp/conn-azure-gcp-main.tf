# Terraform module for Azure and GCP VPN Site-to-Site connection
module "conn_azure_gcp" {
  source = "./modules/conn-azure-gcp"

  # Input variables
  name_prefix   = var.vpn_config.terrarium_id
  shared_secret = var.vpn_config.shared_secret

  # Azure configuration
  azure_region                     = var.vpn_config.azure.region
  azure_resource_group_name        = var.vpn_config.azure.resource_group_name
  azure_bgp_asn                    = var.vpn_config.azure.bgp_asn
  azure_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw.id
  azure_public_ip_addresses        = azurerm_public_ip.pub_ip[*].ip_address
  azure_apipa_cidrs                = var.vpn_config.azure.bgp_peering_cidrs.to_gcp

  # GCP configuration
  gcp_bgp_asn                  = var.vpn_config.gcp.bgp_asn
  gcp_ha_vpn_gateway_self_link = google_compute_ha_vpn_gateway.vpn_gw.self_link
  gcp_router_name              = google_compute_router.vpn_router.name
  gcp_vpn_gateway_addresses    = google_compute_ha_vpn_gateway.vpn_gw.vpn_interfaces[*].ip_address
}
