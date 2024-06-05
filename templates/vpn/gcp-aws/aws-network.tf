# Create a VPN Gateway
resource "aws_vpn_gateway" "vpn_gw" {
  tags = {
    Name = "${var.terrarium-id}-vpn-gw"
  }
  vpc_id = var.aws-vpc-id
}

########################################################
# From here, GCP's resources are required.
########################################################

# Create a Customer Gateway
resource "aws_customer_gateway" "cgw_1" {
  tags = {
    Name = "${var.terrarium-id}-gcp-side-gw-1"
  }
  bgp_asn    = google_compute_router.router_1.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.ha_vpn_gw_1.vpn_interfaces[0].ip_address
  type       = "ipsec.1"
}

# Create a Customer Gateway
resource "aws_customer_gateway" "cgw_2" {
  tags = {
    Name = "${var.terrarium-id}-gcp-side-gw-2"
  }
  bgp_asn    = google_compute_router.router_1.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.ha_vpn_gw_1.vpn_interfaces[1].ip_address
  type       = "ipsec.1"
}

##################################################################
# Create a VPN Connection between the VPN Gateway and the Customer Gateway
resource "aws_vpn_connection" "vpn_cnx_1" {
  tags = {
    Name = "${var.terrarium-id}-cnx-1"
  }
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.cgw_1.id
  type                = "ipsec.1"
}

resource "aws_vpn_connection" "vpn_cnx_2" {
  tags = {
    Name = "${var.terrarium-id}-cnx-2"
  }
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.cgw_2.id
  type                = "ipsec.1"
}
