## AWS side resources/services
# AWS customer gateways (require GCP VPN gateway info)
resource "aws_customer_gateway" "gcp_gw" {
  count = local.is_gcp ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-gcp-side-gw-${count.index + 1}"
  }
  bgp_asn    = var.vpn_config.target_csp.gcp.bgp_asn
  ip_address = google_compute_ha_vpn_gateway.vpn_gw[0].vpn_interfaces[count.index].ip_address
  type       = "ipsec.1"
}

# AWS VPN connections for GCP
# aws_vpn_connection.to_gcp.tunnel1_cgw_inside_address - The RFC 6890 link-local address of the first VPN tunnel (Customer Gateway Side).
# aws_vpn_connection.to_gcp.tunnel1_vgw_inside_address - The RFC 6890 link-local address of the first VPN tunnel (VPN Gateway Side).
resource "aws_vpn_connection" "to_gcp" {
  count = local.is_gcp ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-to-gcp-${count.index + 1}"
  }
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.gcp_gw[count.index].id
  type                = "ipsec.1"
}


## GCP side resources/services
# GCP cloud router
resource "google_compute_router" "router" {
  count = local.is_gcp ? 1 : 0

  name    = "${local.name_prefix}-router"
  network = var.vpn_config.target_csp.gcp.vpc_network_name

  bgp {
    asn               = var.vpn_config.target_csp.gcp.bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

# GCP HA VPN Gateway
resource "google_compute_ha_vpn_gateway" "vpn_gw" {
  count   = local.is_gcp ? 1 : 0
  name    = "${local.name_prefix}-ha-vpn-gw"
  network = var.vpn_config.target_csp.gcp.vpc_network_name
}

# GCP external VPN gateway (require AWS VPN gateway info)
resource "google_compute_external_vpn_gateway" "aws_gw" {
  count = local.is_gcp ? 1 : 0

  name            = "${local.name_prefix}-aws-side-vpn-gw"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "AWS-side VPN gateway"

  interface {
    id         = 0
    ip_address = aws_vpn_connection.to_gcp[0].tunnel1_address
  }
  interface {
    id         = 1
    ip_address = aws_vpn_connection.to_gcp[0].tunnel2_address
  }
  interface {
    id         = 2
    ip_address = aws_vpn_connection.to_gcp[1].tunnel1_address
  }
  interface {
    id         = 3
    ip_address = aws_vpn_connection.to_gcp[1].tunnel2_address
  }
}

# VPN tunnels to configure IPSec VPN connections with the peer VPN gateways (AWS VPN gateways)
resource "google_compute_vpn_tunnel" "to_aws" {
  count = local.is_gcp ? 4 : 0 # 2 tunnels per connection * 2 connections

  name                            = "${local.name_prefix}-tunnel-${count.index + 1}"
  vpn_gateway                     = google_compute_ha_vpn_gateway.vpn_gw[0].self_link
  shared_secret                   = count.index % 2 == 0 ? aws_vpn_connection.to_gcp[floor(count.index / 2)].tunnel1_preshared_key : aws_vpn_connection.to_gcp[floor(count.index / 2)].tunnel2_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gw[0].self_link
  peer_external_gateway_interface = count.index
  router                          = google_compute_router.router[0].name
  ike_version                     = 2
  vpn_gateway_interface           = count.index % 2
}

# Router's network interfaces to connect to the VPN, Interconnect, or other VPC networks.
resource "google_compute_router_interface" "router_interface" {
  count = local.is_gcp ? 4 : 0

  name       = "${local.name_prefix}-interface-${count.index + 1}"
  router     = google_compute_router.router[0].name
  ip_range   = count.index % 2 == 0 ? "${aws_vpn_connection.to_gcp[floor(count.index / 2)].tunnel1_cgw_inside_address}/30" : "${aws_vpn_connection.to_gcp[floor(count.index / 2)].tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.to_aws[count.index].name
}

# Router peers to establish BGP sessions with the BGP peers (AWS VPN gateways)
resource "google_compute_router_peer" "router_peer" {
  count = local.is_gcp ? 4 : 0

  name                      = "${local.name_prefix}-peer-${count.index + 1}"
  router                    = google_compute_router.router[0].name
  peer_ip_address           = count.index % 2 == 0 ? aws_vpn_connection.to_gcp[floor(count.index / 2)].tunnel1_vgw_inside_address : aws_vpn_connection.to_gcp[floor(count.index / 2)].tunnel2_vgw_inside_address
  peer_asn                  = count.index % 2 == 0 ? aws_vpn_connection.to_gcp[floor(count.index / 2)].tunnel1_bgp_asn : aws_vpn_connection.to_gcp[floor(count.index / 2)].tunnel2_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router_interface[count.index].name
}
