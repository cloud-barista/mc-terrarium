
# Create a VPC network
# Note - This is a VPC network. It doesn't seem to have a CIDR block.
# resource "google_compute_network" "my-gcp-vpc-network" {
#   name                    = "my-gcp-vpc-network-name"
#   auto_create_subnetworks = "false" # Disable auto create subnetwork
# }

# Create the first subnet
# resource "google_compute_subnetwork" "my-gcp-subnet-1" {
#   name          = "my-gcp-subnet-1"
#   ip_cidr_range = "192.168.0.0/24"
#   network       = google_compute_network.my-gcp-vpc-network.id
#   region        = "asia-northeast3"
# }

# # Create the second subnet
# resource "google_compute_subnetwork" "my-gcp-subnet-2" {
#   name          = "my-gcp-subnet-2"
#   ip_cidr_range = "192.168.1.0/24"
#   network       = google_compute_network.my-gcp-vpc-network.id
#   region        = "asia-northeast3"
# }

########################################################
# Create a Cloud Router
# Reference: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router
resource "google_compute_router" "my-gcp-router-main" {
  name = "my-gcp-router-main"
  # description = "my cloud router"
  # network = google_compute_network.my-gcp-vpc-network.id
  network = data.google_compute_network.my-imported-gcp-vpc-network.id
  region  = "asia-northeast3"

  bgp {
    # you can choose any number in the private range
    # ASN (Autonomous System Number) you can choose any number in the private range 64512 to 65534 and 4200000000 to 4294967294.
    asn               = 65530
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    # [NOTE] This may specify a single IP address. 
    # advertised_ip_ranges {
    #   range = "1.2.3.4"
    # }

    # [NOTE] This may specify a CIDR range.
    # Q. Exact CIDR range or rough CIDR range?
    # Q. Can I skip to assign a CIDR range?
    # advertised_ip_ranges {
    #   range = "192.168.1.0/24"
    # }
  }
}

########################################################
# Create a VPN Gateway
# Note - Two IP addresses will be automatically allocated for each of your gateway interfaces
resource "google_compute_ha_vpn_gateway" "my-gcp-ha-vpn-gateway" {
  # provider = "google-beta"
  name     = "my-gcp-ha-vpn-gateway-name"
  # network  = google_compute_network.my-gcp-vpc-network.self_link
  network = data.google_compute_network.my-imported-gcp-vpc-network.self_link
}

# Create a peer VPN gateway with peer VPN gateway interfaces
resource "google_compute_external_vpn_gateway" "my-gcp-peer-vpn-gateway" {
  # provider        = "google-beta"
  name            = "my-gcp-peer-vpn-gateway"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "VPN gateway on AWS side"
  interface {
    id         = 0
    ip_address = aws_vpn_connection.my-aws-cx-1.tunnel1_address
  }
  interface {
    id         = 1
    ip_address = aws_vpn_connection.my-aws-cx-1.tunnel2_address
  }
  interface {
    id         = 2
    ip_address = aws_vpn_connection.my-aws-cx-2.tunnel1_address
  }
  interface {
    id         = 3
    ip_address = aws_vpn_connection.my-aws-cx-2.tunnel2_address
  }
}

# Create VPN tunnels between the Cloud VPN gateway and the peer VPN gateway
resource "google_compute_vpn_tunnel" "my-gcp-vpn-tunnel-1" {
  name                            = "my-gcp-vpn-tunnel-1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.self_link
  shared_secret                   = aws_vpn_connection.my-aws-cx-1.tunnel1_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.my-gcp-peer-vpn-gateway.self_link
  peer_external_gateway_interface = 0
  router                          = google_compute_router.my-gcp-router-main.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "my-gcp-vpn-tunnel-2" {
  name                            = "my-gcp-vpn-tunnel-2"
  vpn_gateway                     = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.self_link
  shared_secret                   = aws_vpn_connection.my-aws-cx-1.tunnel2_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.my-gcp-peer-vpn-gateway.self_link
  peer_external_gateway_interface = 1
  router                          = google_compute_router.my-gcp-router-main.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
}

resource "google_compute_vpn_tunnel" "my-gcp-vpn-tunnel-3" {
  name                            = "my-gcp-vpn-tunnel-3"
  vpn_gateway                     = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.self_link
  shared_secret                   = aws_vpn_connection.my-aws-cx-2.tunnel1_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.my-gcp-peer-vpn-gateway.self_link
  peer_external_gateway_interface = 2
  router                          = google_compute_router.my-gcp-router-main.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "my-gcp-vpn-tunnel-4" {
  name                            = "my-gcp-vpn-tunnel-4"
  vpn_gateway                     = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.self_link
  shared_secret                   = aws_vpn_connection.my-aws-cx-2.tunnel2_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.my-gcp-peer-vpn-gateway.self_link
  peer_external_gateway_interface = 3
  router                          = google_compute_router.my-gcp-router-main.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
}

########################################################

# Configure interfaces for the VPN tunnels
resource "google_compute_router_interface" "my-gcp-router-interface-1" {
  name       = "interface-1"
  router     = google_compute_router.my-gcp-router-main.name
  ip_range   = "${aws_vpn_connection.my-aws-cx-1.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-1.name
}

resource "google_compute_router_interface" "my-gcp-router-interface-2" {
  name       = "interface-2"
  router     = google_compute_router.my-gcp-router-main.name
  ip_range   = "${aws_vpn_connection.my-aws-cx-1.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-2.name
}

resource "google_compute_router_interface" "my-gcp-router-interface-3" {
  name       = "interface-3"
  router     = google_compute_router.my-gcp-router-main.name
  ip_range   = "${aws_vpn_connection.my-aws-cx-2.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-3.name
}

resource "google_compute_router_interface" "my-gcp-router-interface-4" {
  name       = "interface-4"
  router     = google_compute_router.my-gcp-router-main.name
  ip_range   = "${aws_vpn_connection.my-aws-cx-2.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-4.name
}

########################################################
# Configure BGP sessions 
resource "google_compute_router_peer" "my-gcp-router-peer-1" {
  name                      = "peer-1"
  router                    = google_compute_router.my-gcp-router-main.name
  peer_ip_address           = aws_vpn_connection.my-aws-cx-1.tunnel1_vgw_inside_address
  peer_asn                  = aws_vpn_connection.my-aws-cx-1.tunnel1_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.my-gcp-router-interface-1.name
}

resource "google_compute_router_peer" "my-gcp-router-peer-2" {
  name                      = "peer-2"
  router                    = google_compute_router.my-gcp-router-main.name
  peer_ip_address           = aws_vpn_connection.my-aws-cx-1.tunnel2_vgw_inside_address
  peer_asn                  = aws_vpn_connection.my-aws-cx-1.tunnel2_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.my-gcp-router-interface-2.name
}

resource "google_compute_router_peer" "my-gcp-router-peer-3" {
  name                      = "peer-3"
  router                    = google_compute_router.my-gcp-router-main.name
  peer_ip_address           = aws_vpn_connection.my-aws-cx-2.tunnel1_vgw_inside_address
  peer_asn                  = aws_vpn_connection.my-aws-cx-2.tunnel1_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.my-gcp-router-interface-3.name
}

resource "google_compute_router_peer" "my-gcp-router-peer-4" {
  name                      = "peer-4"
  router                    = google_compute_router.my-gcp-router-main.name
  peer_ip_address           = aws_vpn_connection.my-aws-cx-2.tunnel2_vgw_inside_address
  peer_asn                  = aws_vpn_connection.my-aws-cx-2.tunnel2_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.my-gcp-router-interface-4.name
}
