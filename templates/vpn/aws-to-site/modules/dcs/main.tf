# Get DCS Subnet CIDR
data "openstack_networking_subnet_v2" "dcs_subnet" {
  subnet_id = var.subnet_id
}

# Create IKE Policy
resource "openstack_vpnaas_ike_policy_v2" "ike" {
  name                 = "${var.name_prefix}-ike-policy"
  description          = "IKE policy for AWS VPN connection"
  ike_version          = "v2"
  encryption_algorithm = "aes-256"
  auth_algorithm       = "sha256"
  pfs                  = "group14"
  # phase1_negotiation_mode = "main"

  lifetime {
    units = "seconds"
    value = 28800
  }
}

# Create IPSec Policy
resource "openstack_vpnaas_ipsec_policy_v2" "ipsec" {
  name                 = "${var.name_prefix}-ipsec-policy"
  description          = "IPSec policy for AWS VPN connection"
  transform_protocol   = "esp"
  encapsulation_mode   = "tunnel"
  encryption_algorithm = "aes-256"
  auth_algorithm       = "sha256"
  pfs                  = "group14"

  lifetime {
    units = "seconds"
    value = 3600
  }
}

# Create VPNaaS Service
resource "openstack_vpnaas_service_v2" "vpn" {
  name        = "${var.name_prefix}-vpn-service"
  description = "VPN Service for AWS connection"
  router_id   = var.router_id
}

# Create Endpoint Group for local subnets
resource "openstack_vpnaas_endpoint_group_v2" "local" {
  name        = "${var.name_prefix}-local-endpoints"
  description = "Local endpoint group"
  type        = "subnet"
  endpoints   = [var.subnet_id]
}

# Create Endpoint Group for peer (AWS) subnets
resource "openstack_vpnaas_endpoint_group_v2" "peer" {
  name        = "${var.name_prefix}-peer-endpoints"
  description = "Peer (AWS) endpoint group"
  type        = "cidr"
  endpoints   = [var.aws_vpc_cidr]
}

# AWS Customer Gateway
resource "aws_customer_gateway" "cgw" {
  bgp_asn    = var.bgp_asn
  ip_address = openstack_vpnaas_service_v2.vpn.external_v4_ip
  type       = "ipsec.1"

  tags = {
    Name = "${var.name_prefix}-cgw"
  }
}

# AWS VPN Connection
resource "aws_vpn_connection" "to_dcs" {
  vpn_gateway_id      = var.aws_vpn_gateway_id
  customer_gateway_id = aws_customer_gateway.cgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "${var.name_prefix}-vpn-connection"
  }
}

# Add Static Route to VPN Connection
resource "aws_vpn_connection_route" "to_dcs" {
  destination_cidr_block = data.openstack_networking_subnet_v2.dcs_subnet.cidr
  vpn_connection_id      = aws_vpn_connection.to_dcs.id
}

# Create Site Connection for Tunnel 1
resource "openstack_vpnaas_site_connection_v2" "to_aws1" {
  name           = "${var.name_prefix}-site-connection-1"
  description    = "Site connection to AWS tunnel 1"
  vpnservice_id  = openstack_vpnaas_service_v2.vpn.id
  ikepolicy_id   = openstack_vpnaas_ike_policy_v2.ike.id
  ipsecpolicy_id = openstack_vpnaas_ipsec_policy_v2.ipsec.id

  peer_address = aws_vpn_connection.to_dcs.tunnel1_address
  peer_id      = aws_vpn_connection.to_dcs.tunnel1_address
  psk          = aws_vpn_connection.to_dcs.tunnel1_preshared_key
  local_id     = openstack_vpnaas_service_v2.vpn.external_v4_ip

  local_ep_group_id = openstack_vpnaas_endpoint_group_v2.local.id
  peer_ep_group_id  = openstack_vpnaas_endpoint_group_v2.peer.id
  mtu               = 1500

  dpd {
    action   = "restart"
    timeout  = 30
    interval = 10
  }
}

# Create Site Connection for Tunnel 2
resource "openstack_vpnaas_site_connection_v2" "to_aws2" {
  name           = "${var.name_prefix}-site-connection-2"
  description    = "Site connection to AWS tunnel 2"
  vpnservice_id  = openstack_vpnaas_service_v2.vpn.id
  ikepolicy_id   = openstack_vpnaas_ike_policy_v2.ike.id
  ipsecpolicy_id = openstack_vpnaas_ipsec_policy_v2.ipsec.id

  peer_address = aws_vpn_connection.to_dcs.tunnel2_address
  peer_id      = aws_vpn_connection.to_dcs.tunnel2_address
  psk          = aws_vpn_connection.to_dcs.tunnel2_preshared_key
  local_id     = openstack_vpnaas_service_v2.vpn.external_v4_ip

  local_ep_group_id = openstack_vpnaas_endpoint_group_v2.local.id
  peer_ep_group_id  = openstack_vpnaas_endpoint_group_v2.peer.id
  mtu               = 1500

  dpd {
    action   = "restart"
    timeout  = 30
    interval = 10
  }
}
