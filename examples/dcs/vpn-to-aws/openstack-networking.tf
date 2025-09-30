# DCS Networking Resources

# Create network
resource "openstack_networking_network_v2" "main" {
  name           = "${var.name_prefix}-network"
  admin_state_up = "true"
}

# Create subnet
resource "openstack_networking_subnet_v2" "main" {
  name            = "${var.name_prefix}-subnet"
  network_id      = openstack_networking_network_v2.main.id
  cidr            = var.openstack_subnet_cidr
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]

  allocation_pool {
    start = cidrhost(var.openstack_subnet_cidr, 10)
    end   = cidrhost(var.openstack_subnet_cidr, 50)
  }
}

# Create router
resource "openstack_networking_router_v2" "main" {
  name                = "${var.name_prefix}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

# Attach subnet to router
resource "openstack_networking_router_interface_v2" "main" {
  router_id = openstack_networking_router_v2.main.id
  subnet_id = openstack_networking_subnet_v2.main.id
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
  router_id   = openstack_networking_router_v2.main.id
}

# Create Endpoint Group for local subnets
resource "openstack_vpnaas_endpoint_group_v2" "local" {
  name        = "${var.name_prefix}-local-endpoints"
  description = "Local endpoint group"
  type        = "subnet"
  endpoints   = [openstack_networking_subnet_v2.main.id]
}

# Create Endpoint Group for peer (AWS) subnets
resource "openstack_vpnaas_endpoint_group_v2" "peer" {
  name        = "${var.name_prefix}-peer-endpoints"
  description = "Peer (AWS) endpoint group"
  type        = "cidr"
  endpoints   = [var.aws_vpc_cidr]
}

# Create Site Connection for Tunnel 1
resource "openstack_vpnaas_site_connection_v2" "to_aws1" {
  name           = "${var.name_prefix}-site-connection-1"
  description    = "Site connection to AWS tunnel 1"
  vpnservice_id  = openstack_vpnaas_service_v2.vpn.id
  ikepolicy_id   = openstack_vpnaas_ike_policy_v2.ike.id
  ipsecpolicy_id = openstack_vpnaas_ipsec_policy_v2.ipsec.id
  psk            = aws_vpn_connection.to_dcs.tunnel1_preshared_key

  peer_address = aws_vpn_connection.to_dcs.tunnel1_address
  peer_id      = aws_vpn_connection.to_dcs.tunnel1_address
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
  psk            = aws_vpn_connection.to_dcs.tunnel2_preshared_key

  peer_address = aws_vpn_connection.to_dcs.tunnel2_address
  peer_id      = aws_vpn_connection.to_dcs.tunnel2_address
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

# Data source for external network (usually named 'public')
data "openstack_networking_network_v2" "external" {
  name = "public"
}
