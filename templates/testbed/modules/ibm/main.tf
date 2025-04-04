# IBM VPC and related resources
resource "ibm_is_vpc" "main" {
  name = "${var.terrarium_id}-vpc"
}

# Add address prefix to VPC, 
resource "ibm_is_vpc_address_prefix" "main" {
  name = "${var.terrarium_id}-addr-prefix"
  vpc  = ibm_is_vpc.main.id
  zone = "au-syd-1" # Sydney, Australia (Zones: au-syd-1, au-syd-2, au-syd-3)
  cidr = "10.4.0.0/16"
}

resource "ibm_is_subnet" "main" {
  depends_on = [ibm_is_vpc_address_prefix.main]

  name            = "${var.terrarium_id}-subnet"
  vpc             = ibm_is_vpc.main.id
  zone            = ibm_is_vpc_address_prefix.main.zone
  ipv4_cidr_block = "10.4.1.0/24"
}

# Security group
resource "ibm_is_security_group" "main" {
  name = "${var.terrarium_id}-sg"
  vpc  = ibm_is_vpc.main.id
}

# Allow inbound SSH
resource "ibm_is_security_group_rule" "ssh" {
  group     = ibm_is_security_group.main.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

# Allow inbound ICMP
resource "ibm_is_security_group_rule" "icmp" {
  group     = ibm_is_security_group.main.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  icmp {
    type = 8
    code = 0
  }
}

# Allow traceroute UDP ports
resource "ibm_is_security_group_rule" "traceroute" {
  group     = ibm_is_security_group.main.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  udp {
    port_min = 33434
    port_max = 33534
  }
}

# Allow all outbound
resource "ibm_is_security_group_rule" "outbound" {
  group     = ibm_is_security_group.main.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# SSH Key
resource "ibm_is_ssh_key" "main" {
  name       = "${var.terrarium_id}-key"
  public_key = var.public_key
}

data "ibm_is_image" "ubuntu_22_04" {
  name = "ibm-ubuntu-22-04-minimal-amd64-1"
}

# Virtual Server Instance (VSI)
resource "ibm_is_instance" "main" {
  name    = "${var.terrarium_id}-vsi"
  vpc     = ibm_is_vpc.main.id
  zone    = ibm_is_vpc_address_prefix.main.zone # Use the same zone as subnet: au-syd-1
  keys    = [ibm_is_ssh_key.main.id]
  image   = data.ibm_is_image.ubuntu_22_04.id # Ubuntu 22.04
  profile = "cx2-2x4"

  primary_network_interface {
    subnet          = ibm_is_subnet.main.id
    security_groups = [ibm_is_security_group.main.id]
  }
}

# Floating IP for public access
resource "ibm_is_floating_ip" "main" {
  name   = "${var.terrarium_id}-fip"
  target = ibm_is_instance.main.primary_network_interface[0].id
}
