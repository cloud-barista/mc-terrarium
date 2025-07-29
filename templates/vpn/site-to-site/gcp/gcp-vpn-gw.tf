## GCP side resources/services
# Data source for existing VPC network
data "google_compute_network" "existing" {
  name = var.vpn_config.gcp.vpc_network_name
}

# Create a Cloud Router for BGP routing
resource "google_compute_router" "vpn_router" {
  name    = "${var.vpn_config.terrarium_id}-vpn-router"
  network = data.google_compute_network.existing.id
  region  = var.vpn_config.gcp.region

  bgp {
    # ASN (Autonomous System Number) for GCP
    asn               = var.vpn_config.gcp.bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

# Create a HA VPN Gateway
# Note - Two IP addresses will be automatically allocated for each of your gateway interfaces
resource "google_compute_ha_vpn_gateway" "vpn_gw" {
  name    = "${var.vpn_config.terrarium_id}-ha-vpn-gateway"
  network = data.google_compute_network.existing.self_link
  region  = var.vpn_config.gcp.region
}
