
# Create a VPC network
# Note - This is a VPC network. It doesn't seem to have a CIDR block.
resource "google_compute_network" "my-gcp-vpc-network" {
  name                    = "my-gcp-vpc-network-name"
  auto_create_subnetworks = "false" # Disable auto create subnetwork
}

# Create the first subnet
resource "google_compute_subnetwork" "my-gcp-subnet-1" {
  name          = "my-gcp-subnet-1"
  ip_cidr_range = "192.168.0.0/24"
  network       = google_compute_network.my-gcp-vpc-network.id
  region        = var.my-gcp-region
}

# Create the second subnet
resource "google_compute_subnetwork" "my-gcp-subnet-2" {
  name          = "my-gcp-subnet-2"
  ip_cidr_range = "192.168.1.0/24"
  network       = google_compute_network.my-gcp-vpc-network.id
  region        = var.my-gcp-region
}

########################################################
# Create a Cloud Router
# Reference: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router
resource "google_compute_router" "my-gcp-router-main" {
  name = "my-gcp-router-main"
  # description = "my cloud router"
  network = google_compute_network.my-gcp-vpc-network.id
  region  = var.my-gcp-region

  bgp {
    # you can choose any number in the private range
    # ASN (Autonomous System Number) you can choose any number in the private range 64512 to 65534 and 4200000000 to 4294967294.
    asn               = var.my-gcp-bgp-asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

  }
}

########################################################
# Create a VPN Gateway
# Note - Two IP addresses will be automatically allocated for each of your gateway interfaces
resource "google_compute_ha_vpn_gateway" "my-gcp-ha-vpn-gateway" {
  # provider = "google-beta"
  name     = "my-gcp-ha-vpn-gateway-name"
  network  = google_compute_network.my-gcp-vpc-network.self_link
}

########################################################
# From here, Azure's resources are required.

# Create a peer VPN gateway with peer VPN gateway interfaces
resource "google_compute_external_vpn_gateway" "my-gcp-peer-vpn-gateway" {
  # provider        = "google-beta"
  name            = "my-gcp-peer-vpn-gateway"
  redundancy_type = "TWO_IPS_REDUNDANCY"
  description     = "VPN gateway on Azure side"
  interface {
    id         = 0
    ip_address = azurerm_public_ip.my-azure-public-ip-1.ip_address
  }
  interface {
    id         = 1
    ip_address = azurerm_public_ip.my-azure-public-ip-2.ip_address
  }
}

# Create VPN tunnels between the Cloud VPN gateway and the peer VPN gateway
resource "google_compute_vpn_tunnel" "my-gcp-vpn-tunnel-1" {
  name                            = "my-gcp-vpn-tunnel-1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.self_link
  shared_secret                   = var.my-shared-secret
  peer_external_gateway           = google_compute_external_vpn_gateway.my-gcp-peer-vpn-gateway.self_link
  peer_external_gateway_interface = 0
  router                          = google_compute_router.my-gcp-router-main.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "my-gcp-vpn-tunnel-2" {
  name                            = "my-gcp-vpn-tunnel-2"
  vpn_gateway                     = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.self_link
  shared_secret                   = var.my-shared-secret
  peer_external_gateway           = google_compute_external_vpn_gateway.my-gcp-peer-vpn-gateway.self_link
  peer_external_gateway_interface = 1
  router                          = google_compute_router.my-gcp-router-main.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
}

########################################################

# Configure interfaces for the VPN tunnels
resource "google_compute_router_interface" "my-gcp-router-interface-1" {
  name       = "interface-1"
  router     = google_compute_router.my-gcp-router-main.name
  ip_range   = "169.254.21.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-1.name
}

resource "google_compute_router_interface" "my-gcp-router-interface-2" {
  name       = "interface-2"
  router     = google_compute_router.my-gcp-router-main.name
  ip_range   = "169.254.22.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-2.name
}

########################################################
# Configure BGP sessions 
resource "google_compute_router_peer" "my-gcp-router-peer-1" {
  name                      = "peer-1"
  router                    = google_compute_router.my-gcp-router-main.name
  peer_ip_address           = "169.254.21.1"
  peer_asn                  = var.my-azure-bgp-asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.my-gcp-router-interface-1.name
}

resource "google_compute_router_peer" "my-gcp-router-peer-2" {
  name                      = "peer-2"
  router                    = google_compute_router.my-gcp-router-main.name
  peer_ip_address           = "169.254.22.1"
  peer_asn                  = var.my-azure-bgp-asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.my-gcp-router-interface-2.name
}
