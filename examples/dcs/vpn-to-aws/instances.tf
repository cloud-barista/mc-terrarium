# Test Instances for VPN Connectivity

# Data sources for AMI and key pair
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# AWS EC2 Instance
resource "aws_instance" "test" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.main.id]
  associate_public_ip_address = true

  # Use existing key pair or create one
  key_name = aws_key_pair.main.key_name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx htop
              echo "<h1>AWS Instance - ${var.name_prefix}</h1>" > /var/www/html/index.html
              echo "<p>Private IP: $(hostname -I | awk '{print $1}')</p>" >> /var/www/html/index.html
              systemctl start nginx
              systemctl enable nginx
              EOF
  )

  tags = {
    Name = "${var.name_prefix}-aws-instance"
  }
}

# Data sources for DCS
data "openstack_images_image_v2" "ubuntu" {
  name_regex  = "(?i)ubuntu.*22"
  most_recent = true
}

data "openstack_compute_flavor_v2" "small" {
  name = "m1.small"
}

# Create port for DCS instance (better OpenStack 2025.1 compatibility)
resource "openstack_networking_port_v2" "test" {
  name               = "${var.name_prefix}-port-test"
  network_id         = openstack_networking_network_v2.main.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.main.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.main.id
  }
}

# DCS Instance
resource "openstack_compute_instance_v2" "test" {
  name      = "${var.name_prefix}-openstack-instance"
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_id = data.openstack_compute_flavor_v2.small.id
  key_pair  = openstack_compute_keypair_v2.main.name

  # Use explicit port instead of network UUID and security groups
  network {
    port = openstack_networking_port_v2.test.id
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx htop
              echo "<h1>DCS Instance - ${var.name_prefix}</h1>" > /var/www/html/index.html
              echo "<p>Private IP: $(hostname -I | awk '{print $1}')</p>" >> /var/www/html/index.html
              systemctl start nginx
              systemctl enable nginx
              EOF
  )

  # Metadata
  metadata = {
    name_prefix = var.name_prefix
    created_by  = "opentofu"
  }
}

# Floating IP for DCS instance
resource "openstack_networking_floatingip_v2" "test" {
  pool        = data.openstack_networking_network_v2.external.name
  description = "Floating IP for ${var.name_prefix}-openstack-instance"
}

# Associate floating IP with instance using explicit port
resource "openstack_networking_floatingip_associate_v2" "test" {
  floating_ip = openstack_networking_floatingip_v2.test.address
  port_id     = openstack_networking_port_v2.test.id
}
