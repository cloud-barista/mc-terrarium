# Get available zones
data "alicloud_zones" "available" {
  available_resource_creation = "VSwitch"
}

# Alibaba Cloud VPC
resource "alicloud_vpc" "main" {
  vpc_name   = "${var.terrarium_id}-vpc"
  cidr_block = "10.3.0.0/16"
}

# zones = {
#   count = length(data.alicloud_zones.available.zones)
#   ids   = data.alicloud_zones.available.zones[*].id
# }

# resource "alicloud_vswitch" "main" {
#   count = 2

#   vswitch_name = "${var.terrarium_id}-vswitch-${data.alicloud_zones.available.zones[count.index % length(data.alicloud_zones.available.zones)].id}"
#   vpc_id       = alicloud_vpc.main.id
#   cidr_block   = "10.3.${count + 1}.0/24"
#   zone_id      = data.alicloud_zones.available.zones[count.index % length(data.alicloud_zones.available.zones)].id
# }

resource "alicloud_vswitch" "main" {
  vswitch_name = "${var.terrarium_id}-vswitch-${data.alicloud_zones.available.zones[0 % length(data.alicloud_zones.available.zones)].id}"
  vpc_id       = alicloud_vpc.main.id
  cidr_block   = "10.3.1.0/24"
  zone_id      = data.alicloud_zones.available.zones[0 % length(data.alicloud_zones.available.zones)].id
}

resource "alicloud_vswitch" "secondary" {
  vswitch_name = "${var.terrarium_id}-vswitch-${data.alicloud_zones.available.zones[1 % length(data.alicloud_zones.available.zones)].id}"
  vpc_id       = alicloud_vpc.main.id
  cidr_block   = "10.3.2.0/24"
  zone_id      = data.alicloud_zones.available.zones[1 % length(data.alicloud_zones.available.zones)].id
}


# Route Table
resource "alicloud_route_table" "main" {
  vpc_id           = alicloud_vpc.main.id
  route_table_name = "${var.terrarium_id}-route-table"
}

resource "alicloud_route_table_attachment" "main" {
  vswitch_id     = alicloud_vswitch.main.id
  route_table_id = alicloud_route_table.main.id
}

resource "alicloud_route_table_attachment" "secondary" {
  vswitch_id     = alicloud_vswitch.secondary.id
  route_table_id = alicloud_route_table.main.id
}

# Security Group
resource "alicloud_security_group" "main" {
  # [NOTE] The following line will cause an error in the Terraform/OpenTofu language server.
  # It won't affect the actual Terraform deployment.
  # It will be resolved when the Terraform/OpenTofu language server is updated.
  security_group_name = "${var.terrarium_id}-sg"
  vpc_id              = alicloud_vpc.main.id
}

resource "alicloud_security_group_rule" "allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  security_group_id = alicloud_security_group.main.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_icmp" {
  type              = "ingress"
  ip_protocol       = "icmp"
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.main.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  ip_protocol       = "all"
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.main.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_traceroute" {
  type              = "ingress"
  ip_protocol       = "udp"
  port_range        = "33434/33534"
  security_group_id = alicloud_security_group.main.id
  cidr_ip           = "0.0.0.0/0"
}

# SSH Key Pair
resource "alicloud_ecs_key_pair" "main" {
  key_pair_name = "${var.terrarium_id}-key"
  public_key    = tls_private_key.ssh.public_key_openssh
}

# ECS Instance
resource "alicloud_instance" "main" {
  instance_name              = "${var.terrarium_id}-ecs"
  instance_type              = "ecs.t6-c1m1.large"
  image_id                   = "ubuntu_22_04_x64_20G_alibase_20230515.vhd"
  system_disk_category       = "cloud_essd"
  system_disk_size           = 20
  security_groups            = [alicloud_security_group.main.id]
  vswitch_id                 = alicloud_vswitch.main.id
  internet_max_bandwidth_out = 5
  key_name                   = alicloud_ecs_key_pair.main.key_pair_name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -euo pipefail

              # Redirect output to log file for debugging
              exec > >(tee /var/log/user-data-debug.log) 2>&1

              # Ensure ubuntu user exists with correct permissions
              if ! id "ubuntu" &>/dev/null; then
                  # Create user with sudo privileges
                  useradd -m -s /bin/bash -G sudo ubuntu
              else
                  # Ensure user is in sudo group if already exists
                  usermod -aG sudo ubuntu
              fi

              # Set up sudo access for ubuntu user without password
              echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/ubuntu
              chmod 440 /etc/sudoers.d/ubuntu

              # Set up SSH directory
              mkdir -p /home/ubuntu/.ssh
              chmod 700 /home/ubuntu/.ssh

              # Add SSH public key
              echo "${tls_private_key.ssh.public_key_openssh}" > /home/ubuntu/.ssh/authorized_keys
              chmod 600 /home/ubuntu/.ssh/authorized_keys
              chown -R ubuntu:ubuntu /home/ubuntu/.ssh

              # Harden SSH configuration
              sed -i -e 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' \
                    -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' \
                    -e 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' \
                    /etc/ssh/sshd_config

              # Restart SSH service
              systemctl restart ssh

              # Verify user creation and sudo access
              id ubuntu
              sudo -l -U ubuntu
              EOF
  )

  tags = {
    Environment = var.terrarium_id
  }
}
