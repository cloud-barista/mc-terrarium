data "google_compute_network" "injected_vpc_network" {
  name = var.gcp-vpc-network-name
}

# Create a Cloud Router
# Reference: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router
resource "google_compute_router" "router_1" {
  name = "router-1-name"
  # description = "my cloud router"
  network = data.google_compute_network.injected_vpc_network.id
  # region  = var.gcp-region

  bgp {
    # you can choose any number in the private range
    # ASN (Autonomous System Number) you can choose any number in the private range 64512 to 65534 and 4200000000 to 4294967294.
    asn               = var.gcp-bgp-asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

  }
}

# Create a VPN Gateway
# Note - Two IP addresses will be automatically allocated for each of your gateway interfaces
resource "google_compute_ha_vpn_gateway" "ha_vpn_gw_1" {
  name     = "ha-vpn-gw-1-name"
  network = data.google_compute_network.injected_vpc_network.self_link
}

########################################################
# From here, AWS's resources are required.
########################################################

# Create a peer VPN gateway with peer VPN gateway interfaces
resource "google_compute_external_vpn_gateway" "external_vpn_gw_1" {
  name            = "aws-side-gw-1-name"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "AWS-side VPN gateway"
  interface {
    id         = 0
    ip_address = aws_vpn_connection.vpn_cnx_1.tunnel1_address
  }
  interface {
    id         = 1
    ip_address = aws_vpn_connection.vpn_cnx_1.tunnel2_address
  }
  interface {
    id         = 2
    ip_address = aws_vpn_connection.vpn_cnx_2.tunnel1_address
  }
  interface {
    id         = 3
    ip_address = aws_vpn_connection.vpn_cnx_2.tunnel2_address
  }
}

# Create VPN tunnels between the Cloud VPN gateway and the peer VPN gateway
resource "google_compute_vpn_tunnel" "vpn_tunnel_1" {
  name                            = "vpn-tunnel-1-name"
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_vpn_gw_1.self_link
  shared_secret                   = aws_vpn_connection.vpn_cnx_1.tunnel1_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.external_vpn_gw_1.self_link
  peer_external_gateway_interface = 0
  router                          = google_compute_router.router_1.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "vpn_tunnel_2" {
  name                            = "vpn-tunnel-2-name"
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_vpn_gw_1.self_link
  shared_secret                   = aws_vpn_connection.vpn_cnx_1.tunnel2_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.external_vpn_gw_1.self_link
  peer_external_gateway_interface = 1
  router                          = google_compute_router.router_1.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
}

resource "google_compute_vpn_tunnel" "vpn_tunnel_3" {
  name                            = "vpn-tunnel-3-name"
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_vpn_gw_1.self_link
  shared_secret                   = aws_vpn_connection.vpn_cnx_2.tunnel1_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.external_vpn_gw_1.self_link
  peer_external_gateway_interface = 2
  router                          = google_compute_router.router_1.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "vpn_tunnel_4" {
  name                            = "vpn-tunnel-4-name"
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_vpn_gw_1.self_link
  shared_secret                   = aws_vpn_connection.vpn_cnx_2.tunnel2_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.external_vpn_gw_1.self_link
  peer_external_gateway_interface = 3
  router                          = google_compute_router.router_1.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
}

########################################################

# Configure interfaces for the VPN tunnels
resource "google_compute_router_interface" "router_interface_1" {
  name       = "interface-1-name"
  router     = google_compute_router.router_1.name
  ip_range   = "${aws_vpn_connection.vpn_cnx_1.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel_1.name
}

resource "google_compute_router_interface" "router_interface_2" {
  name       = "interface-2-name"
  router     = google_compute_router.router_1.name
  ip_range   = "${aws_vpn_connection.vpn_cnx_1.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel_2.name
}

resource "google_compute_router_interface" "router_interface_3" {
  name       = "interface-3-name"
  router     = google_compute_router.router_1.name
  ip_range   = "${aws_vpn_connection.vpn_cnx_2.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel_3.name
}

resource "google_compute_router_interface" "router_interface_4" {
  name       = "interface-4-name"
  router     = google_compute_router.router_1.name
  ip_range   = "${aws_vpn_connection.vpn_cnx_2.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel_4.name
}

########################################################
# Configure BGP sessions 
resource "google_compute_router_peer" "router_peer_1" {
  name                      = "peer-1-name"
  router                    = google_compute_router.router_1.name
  peer_ip_address           = aws_vpn_connection.vpn_cnx_1.tunnel1_vgw_inside_address
  peer_asn                  = aws_vpn_connection.vpn_cnx_1.tunnel1_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router_interface_1.name
}

resource "google_compute_router_peer" "router_peer_2" {
  name                      = "peer-2-name"
  router                    = google_compute_router.router_1.name
  peer_ip_address           = aws_vpn_connection.vpn_cnx_1.tunnel2_vgw_inside_address
  peer_asn                  = aws_vpn_connection.vpn_cnx_1.tunnel2_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router_interface_2.name
}

resource "google_compute_router_peer" "router_peer_3" {
  name                      = "peer-3-name"
  router                    = google_compute_router.router_1.name
  peer_ip_address           = aws_vpn_connection.vpn_cnx_2.tunnel1_vgw_inside_address
  peer_asn                  = aws_vpn_connection.vpn_cnx_2.tunnel1_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router_interface_3.name
}

resource "google_compute_router_peer" "router_peer_4" {
  name                      = "peer-4-name"
  router                    = google_compute_router.router_1.name
  peer_ip_address           = aws_vpn_connection.vpn_cnx_2.tunnel2_vgw_inside_address
  peer_asn                  = aws_vpn_connection.vpn_cnx_2.tunnel2_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router_interface_4.name
}
