# Security Groups for AWS and DCS

# AWS Security Group
resource "aws_security_group" "main" {
  name        = "${var.name_prefix}-sg"
  description = "Security group for VPN traffic"
  vpc_id      = aws_vpc.main.id

  # Allow inbound traffic from DCS network
  ingress {
    description = "All traffic from DCS network"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.openstack_network_cidr]
  }

  ingress {
    description = "ICMP from DCS network"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.openstack_network_cidr]
  }

  # Allow ICMP from anywhere for ping testing
  ingress {
    description = "ICMP from anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg"
  }
}

# DCS Security Group
resource "openstack_networking_secgroup_v2" "main" {
  name        = "${var.name_prefix}-sg"
  description = "Security group for VPN traffic"
}

# Allow inbound traffic from AWS network
resource "openstack_networking_secgroup_rule_v2" "aws_tcp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = var.aws_vpc_cidr
  security_group_id = openstack_networking_secgroup_v2.main.id
}

resource "openstack_networking_secgroup_rule_v2" "aws_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = var.aws_vpc_cidr
  security_group_id = openstack_networking_secgroup_v2.main.id
}

# Allow ICMP from anywhere for ping testing
resource "openstack_networking_secgroup_rule_v2" "icmp_all" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.main.id
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
}

# Note: Egress rules are typically created by default in OpenStack
# No need to explicitly create egress_all rule to avoid conflicts
