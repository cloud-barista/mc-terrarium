# DCS (DevStack Cloud Service) Compute Resources

# Generate SSH key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Data sources for image and flavor
data "openstack_images_image_v2" "ubuntu" {
  name        = var.instance_image
  most_recent = true
}

data "openstack_compute_flavor_v2" "medium" {
  name = var.instance_flavor
}

# Create key pair using generated SSH key
resource "openstack_compute_keypair_v2" "main" {
  name       = "${var.name_prefix}-keypair"
  public_key = tls_private_key.ssh.public_key_openssh
}

# Create port for main instance (better OpenStack 2025.1 compatibility)
resource "openstack_networking_port_v2" "main" {
  name               = "${var.name_prefix}-port-main"
  network_id         = openstack_networking_network_v2.main.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.main.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.main.id
  }
}

# Create compute instance
resource "openstack_compute_instance_v2" "main" {
  name      = "${var.name_prefix}-instance"
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_id = data.openstack_compute_flavor_v2.medium.id
  key_pair  = openstack_compute_keypair_v2.main.name

  # Use explicit port instead of network UUID
  network {
    port = openstack_networking_port_v2.main.id
  }

  # User data script to install basic packages
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    instance_name = "${var.name_prefix}-instance"
  }))

  # Metadata
  metadata = {
    name_prefix = var.name_prefix
    created_by  = "opentofu"
  }
}

# Create floating IP
resource "openstack_networking_floatingip_v2" "main" {
  pool        = data.openstack_networking_network_v2.external.name
  description = "Floating IP for ${var.name_prefix}-instance"
}

# Associate floating IP with instance using explicit port
resource "openstack_networking_floatingip_associate_v2" "main" {
  floating_ip = openstack_networking_floatingip_v2.main.address
  port_id     = openstack_networking_port_v2.main.id
}

# Create port for secondary instance (better OpenStack 2025.1 compatibility)
resource "openstack_networking_port_v2" "secondary" {
  name               = "${var.name_prefix}-port-secondary"
  network_id         = openstack_networking_network_v2.main.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.main.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.main.id
  }
}

# Create additional instance for testing connectivity
resource "openstack_compute_instance_v2" "secondary" {
  name      = "${var.name_prefix}-instance-2"
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_id = data.openstack_compute_flavor_v2.medium.id
  key_pair  = openstack_compute_keypair_v2.main.name

  # Use explicit port instead of network UUID
  network {
    port = openstack_networking_port_v2.secondary.id
  }

  # User data script
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    instance_name = "${var.name_prefix}-instance-2"
  }))

  # Metadata
  metadata = {
    name_prefix = var.name_prefix
    created_by  = "opentofu"
    role        = "secondary"
  }
}

# Create second floating IP for secondary instance
resource "openstack_networking_floatingip_v2" "secondary" {
  pool        = data.openstack_networking_network_v2.external.name
  description = "Floating IP for ${var.name_prefix}-instance-2"
}

# Associate second floating IP using explicit port
resource "openstack_networking_floatingip_associate_v2" "secondary" {
  floating_ip = openstack_networking_floatingip_v2.secondary.address
  port_id     = openstack_networking_port_v2.secondary.id
}
