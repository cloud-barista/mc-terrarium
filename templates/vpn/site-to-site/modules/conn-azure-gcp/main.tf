## Azure side resources/services
# Azure Local Network Gateway (require GCP VPN gateway info)
resource "azurerm_local_network_gateway" "gcp_gw" {
  count = 2

  name                = "${var.name_prefix}-gcp-side-${count.index + 1}"
  location            = var.azure_region
  resource_group_name = var.azure_resource_group_name

  gateway_address = var.gcp_vpn_gateway_addresses[count.index]

  bgp_settings {
    asn = var.gcp_bgp_asn
    # GCP BGP peer address: Use .1 address from APIPA CIDR (using 1st and 3rd CIDRs)
    # Azure VPN Gateway uses .2, so GCP uses .1
    bgp_peering_address = cidrhost(var.azure_apipa_cidrs[count.index * 2], 1)
  }
}

# Azure VPN Connection 
resource "azurerm_virtual_network_gateway_connection" "to_gcp" {
  count = 2

  name                = "${var.name_prefix}-to-gcp-${count.index + 1}"
  location            = var.azure_region
  resource_group_name = var.azure_resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = var.azure_virtual_network_gateway_id
  local_network_gateway_id   = azurerm_local_network_gateway.gcp_gw[count.index].id
  shared_key                 = var.shared_secret

  enable_bgp = true
}

## GCP side resources/services
# Create a peer VPN gateway with peer VPN gateway interfaces (Azure)
resource "google_compute_external_vpn_gateway" "azure_peer_gw" {
  name            = "${var.name_prefix}-azure-peer-vpn-gateway"
  redundancy_type = "TWO_IPS_REDUNDANCY"
  description     = "VPN gateway on Azure side"

  interface {
    id         = 0
    ip_address = var.azure_public_ip_addresses[0]
  }
  interface {
    id         = 1
    ip_address = var.azure_public_ip_addresses[1]
  }
}

# Create VPN tunnels between the GCP HA VPN gateway and the Azure VPN gateway
resource "google_compute_vpn_tunnel" "to_azure" {
  count = 2

  name                            = "${var.name_prefix}-to-azure-${count.index + 1}"
  vpn_gateway                     = var.gcp_ha_vpn_gateway_self_link
  shared_secret                   = var.shared_secret
  peer_external_gateway           = google_compute_external_vpn_gateway.azure_peer_gw.self_link
  peer_external_gateway_interface = count.index
  router                          = var.gcp_router_name
  ike_version                     = 2
  vpn_gateway_interface           = count.index
}

# Configure interfaces for the VPN tunnels
resource "google_compute_router_interface" "tunnel_interfaces" {
  count = 2

  name   = "${var.name_prefix}-interface-${count.index + 1}"
  router = var.gcp_router_name
  # GCP router interface: Use .1 address from APIPA CIDR (using 1st[0] and 3rd[2] CIDRs)
  # Azure VPN Gateway uses .2, so GCP uses .1
  ip_range   = "${cidrhost(var.azure_apipa_cidrs[count.index * 2], 1)}/30"
  vpn_tunnel = google_compute_vpn_tunnel.to_azure[count.index].name
}

# Configure BGP sessions 
resource "google_compute_router_peer" "azure_peers" {
  count = 2

  name   = "${var.name_prefix}-peer-${count.index + 1}"
  router = var.gcp_router_name
  # Azure BGP peer address: Use .2 address from APIPA CIDR (using 1st[0] and 3rd[2] CIDRs)
  # Azure VPN Gateway uses .2, GCP uses .1 - this points to Azure's address
  peer_ip_address           = cidrhost(var.azure_apipa_cidrs[count.index * 2], 2)
  peer_asn                  = var.azure_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.tunnel_interfaces[count.index].name
}
