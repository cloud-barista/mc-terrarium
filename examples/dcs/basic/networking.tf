# DCS (DevStack Cloud Service) Networking Resources

# Data source for external network
data "openstack_networking_network_v2" "external" {
  name = var.external_network_name
}

# Create main network
resource "openstack_networking_network_v2" "main" {
  admin_state_up = true
  name           = "${var.name_prefix}-network"
  description    = "Main network for ${var.name_prefix}"
}

# Create subnet
resource "openstack_networking_subnet_v2" "main" {
  name            = "${var.name_prefix}-subnet"
  network_id      = openstack_networking_network_v2.main.id
  cidr            = var.subnet_cidr
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
  description     = "Main subnet for ${var.name_prefix}"

  # Define allocation pool (reserve first 10 IPs for infrastructure)
  allocation_pool {
    start = cidrhost(var.subnet_cidr, 10)
    end   = cidrhost(var.subnet_cidr, -2)
  }

  # Gateway IP (first usable IP in the subnet)
  gateway_ip = cidrhost(var.subnet_cidr, 1)
}

# Create router
resource "openstack_networking_router_v2" "main" {
  name                = "${var.name_prefix}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
  description         = "Main router for ${var.name_prefix}"
}

# Attach subnet to router
resource "openstack_networking_router_interface_v2" "main" {
  router_id = openstack_networking_router_v2.main.id
  subnet_id = openstack_networking_subnet_v2.main.id
}

# Create security group
resource "openstack_networking_secgroup_v2" "main" {
  name        = "${var.name_prefix}-sg"
  description = "Security group for ${var.name_prefix} instances"
}

# Allow SSH access
resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.main.id
  description       = "Allow SSH access"
}

# Allow HTTP access
resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.main.id
  description       = "Allow HTTP access"
}

# Allow HTTPS access
resource "openstack_networking_secgroup_rule_v2" "https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.main.id
  description       = "Allow HTTPS access"
}

# Allow all ICMP traffic (ping, traceroute, etc.)
resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.main.id
  description       = "Allow all ICMP (ping, traceroute)"
}

# Allow UDP for traceroute (high ports 33434-33523)
resource "openstack_networking_secgroup_rule_v2" "udp_traceroute" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 33434
  port_range_max    = 33523
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.main.id
  description       = "Allow UDP traceroute"
}

# Allow outbound ICMP for responses
resource "openstack_networking_secgroup_rule_v2" "icmp_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.main.id
  description       = "Allow outbound ICMP"
}

# Allow internal communication
resource "openstack_networking_secgroup_rule_v2" "internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id   = openstack_networking_secgroup_v2.main.id
  security_group_id = openstack_networking_secgroup_v2.main.id
  description       = "Allow internal communication"
}
