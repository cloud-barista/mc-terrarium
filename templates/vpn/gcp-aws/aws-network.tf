# Create a VPN Gateway
resource "aws_vpn_gateway" "vpn_gw" {
  tags = {
    Name = "vpn-gw-name"
  }
  vpc_id = var.aws-vpc-id
}

########################################################
# From here, GCP's resources are required.
########################################################

# Create a Customer Gateway
resource "aws_customer_gateway" "cgw_1" {
  tags = {
    Name = "gcp-side-gw-1-name"
  }
  bgp_asn    = google_compute_router.router_1.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.ha_vpn_gw_1.vpn_interfaces[0].ip_address
  type       = "ipsec.1"
}

# Create a Customer Gateway
resource "aws_customer_gateway" "cgw_2" {
  tags = {
    Name = "gcp-side-gw-2-name"
  }
  bgp_asn    = google_compute_router.router_1.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.ha_vpn_gw_1.vpn_interfaces[1].ip_address
  type       = "ipsec.1"
}

##################################################################
# Create a VPN Connection between the VPN Gateway and the Customer Gateway
resource "aws_vpn_connection" "vpn_cnx_1" {
  tags = {
    Name = "cnx-1-name"
  }
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.cgw_1.id
  type                = "ipsec.1"
}

resource "aws_vpn_connection" "vpn_cnx_2" {
  tags = {
    Name = "cnx-2-name"
  }
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.cgw_2.id
  type                = "ipsec.1"
}
