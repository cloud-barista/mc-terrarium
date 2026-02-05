# Network
resource "openstack_networking_network_v2" "main" {
  name           = "${var.terrarium_id}-network"
  admin_state_up = "true"
}

# Subnet
resource "openstack_networking_subnet_v2" "main" {
  name            = "${var.terrarium_id}-subnet"
  network_id      = openstack_networking_network_v2.main.id
  cidr            = "10.6.0.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Router
data "openstack_networking_network_v2" "external" {
  name = var.external_network_name
}

resource "openstack_networking_router_v2" "main" {
  name                = "${var.terrarium_id}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
  distributed         = false
}

resource "openstack_networking_router_interface_v2" "main" {
  router_id = openstack_networking_router_v2.main.id
  subnet_id = openstack_networking_subnet_v2.main.id
}

# Key Pair
resource "openstack_compute_keypair_v2" "main" {
  name       = "${var.terrarium_id}-key"
  public_key = var.public_key
}

# Security Group
resource "openstack_networking_secgroup_v2" "main" {
  name        = "${var.terrarium_id}-sg"
  description = "Allow SSH and ICMP"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.main.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.main.id
}

# Data sources for Image and Flavor
data "openstack_images_image_v2" "ubuntu" {
  name_regex  = var.image_name
  most_recent = true
}

data "openstack_compute_flavor_v2" "flavor" {
  name = var.flavor_name
}

# Create port for DCS instance (better compatibility)
resource "openstack_networking_port_v2" "main" {
  name               = "${var.terrarium_id}-port"
  network_id         = openstack_networking_network_v2.main.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.main.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.main.id
  }
}

# Instance
resource "openstack_compute_instance_v2" "main" {
  name      = "${var.terrarium_id}-vm"
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_id = data.openstack_compute_flavor_v2.flavor.id
  key_pair  = openstack_compute_keypair_v2.main.name

  network {
    port = openstack_networking_port_v2.main.id
  }
}

# Floating IP
resource "openstack_networking_floatingip_v2" "main" {
  pool = var.external_network_name
}

resource "openstack_compute_floatingip_associate_v2" "main" {
  floating_ip = openstack_networking_floatingip_v2.main.address
  instance_id = openstack_compute_instance_v2.main.id
}
