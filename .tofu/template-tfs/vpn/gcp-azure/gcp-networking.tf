
# # Create a VPC network
# # Note - This is a VPC network. It doesn't seem to have a CIDR block.
# resource "google_compute_network" "injected_vpc_network" {
#   name                    = "injected_vpc_network-name"
#   auto_create_subnetworks = "false" # Disable auto create subnetwork
# }

# # Create the first subnet
# resource "google_compute_subnetwork" "my-gcp-subnet-1" {
#   name          = "my-gcp-subnet-1"
#   ip_cidr_range = "192.168.0.0/24"
#   network       = google_compute_network.injected_vpc_network.id
#   region        = var.gcp-region
# }

# # Create the second subnet
# resource "google_compute_subnetwork" "injected_vpc_subnetwork" {
#   name          = "injected_vpc_subnetwork"
#   ip_cidr_range = "192.168.1.0/24"
#   network       = google_compute_network.injected_vpc_network.id
#   region        = var.gcp-region
# }

data "google_compute_network" "injected_vpc_network" {
  name = var.gcp-vpc-network-name
}


########################################################
# Create a Cloud Router
# Reference: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router
resource "google_compute_router" "gcp_router_1" {
  name = "gcp-router-1-name"
  # description = "my cloud router"
  network = data.google_compute_network.injected_vpc_network.name
  # region  = var.gcp-region

  bgp {
    # you can choose any number in the private range
    # ASN (Autonomous System Number) you can choose any number in the private range 64512 to 65534 and 4200000000 to 4294967294.
    asn               = var.gcp-bgp-asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

  }
}

########################################################
# Create a VPN Gateway
# Note - Two IP addresses will be automatically allocated for each of your gateway interfaces
resource "google_compute_ha_vpn_gateway" "ha_vpn_gw_1" {
  # provider = "google-beta"
  name     = "ha-vpn-gw-1-name"
  network  = data.google_compute_network.injected_vpc_network.name
}

########################################################
# From here, Azure's resources are required.

# Create a peer VPN gateway with peer VPN gateway interfaces
resource "google_compute_external_vpn_gateway" "peer_vpn_gw_1" {
  # provider        = "google-beta"
  name            = "azure-side-vpn-gw-1"
  redundancy_type = "TWO_IPS_REDUNDANCY"
  description     = "VPN gateway on Azure side"

  interface {
    id         = 0
    ip_address = azurerm_public_ip.vpn_gw_pub_ip_1.ip_address
  }
  
  interface {
    id         = 1
    ip_address = azurerm_public_ip.vpn_gw_pub_ip_2.ip_address
  }
}

# Create VPN tunnels between the Cloud VPN gateway and the peer VPN gateway
resource "google_compute_vpn_tunnel" "gcp_and_azure_tunnel_1" {
  name                            = "gcp-and-azure-tunnel-1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_vpn_gw_1.self_link
  shared_secret                   = var.preshared-secret
  # shared_secret                   = azurerm_virtual_network_gateway_connection.gcp_and_azure_cnx_1.shared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.peer_vpn_gw_1.self_link
  peer_external_gateway_interface = 0
  router                          = google_compute_router.gcp_router_1.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "gcp_and_azure_tunnel_2" {
  name                            = "gcp-and-azure-tunnel-2"
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_vpn_gw_1.self_link
  shared_secret                   = var.preshared-secret
  # shared_secret                   = azurerm_virtual_network_gateway_connection.gcp_and_azure_cnx_2.shared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.peer_vpn_gw_1.self_link
  peer_external_gateway_interface = 1
  router                          = google_compute_router.gcp_router_1.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
}

########################################################

# Configure interfaces for the VPN tunnels
resource "google_compute_router_interface" "interface_for_tunnel_1" {
  name       = "interface-1"
  router     = google_compute_router.gcp_router_1.name
  ip_range   = "169.254.21.2/30"
  # ip_range = azurerm_virtual_network_gateway.vpn_gw_1.bgp_settings[0].peering_addresses[0].apipa_addresses[0]
  
  vpn_tunnel = google_compute_vpn_tunnel.gcp_and_azure_tunnel_1.name
}

resource "google_compute_router_interface" "interface_for_tunnel_2" {
  name       = "interface-2"
  router     = google_compute_router.gcp_router_1.name
  ip_range   = "169.254.22.2/30"
  # ip_range = azurerm_virtual_network_gateway.vpn_gw_1.bgp_settings[0].peering_addresses[1].apipa_addresses[0]
  vpn_tunnel = google_compute_vpn_tunnel.gcp_and_azure_tunnel_2.name
}

########################################################
# Configure BGP sessions 
resource "google_compute_router_peer" "bgp_session_1" {
  name                      = "peer-1"
  router                    = google_compute_router.gcp_router_1.name
  # peer_ip_address           = "169.254.21.1"
  peer_ip_address           = azurerm_virtual_network_gateway.vpn_gw_1.bgp_settings[0].peering_addresses[0].apipa_addresses[0]
  # peer_asn                  = var.azure-bgp-asn
  peer_asn                  = azurerm_virtual_network_gateway.vpn_gw_1.bgp_settings[0].asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.interface_for_tunnel_1.name
}

resource "google_compute_router_peer" "bgp_session_2" {
  name                      = "peer-2"
  router                    = google_compute_router.gcp_router_1.name
  # peer_ip_address           = "169.254.22.1"
  peer_ip_address           = azurerm_virtual_network_gateway.vpn_gw_1.bgp_settings[0].peering_addresses[1].apipa_addresses[0]
  # peer_asn                  = var.azure-bgp-asn
  peer_asn                  = azurerm_virtual_network_gateway.vpn_gw_1.bgp_settings[0].asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.interface_for_tunnel_2.name
}
