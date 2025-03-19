# Get available zones using the recommended data source
data "tencentcloud_availability_zones_by_product" "available" {
  product = "cvm" # For Compute instances
}

# Find Ubuntu 22.04 image with more specific regex
data "tencentcloud_images" "ubuntu" {
  image_type       = ["PUBLIC_IMAGE"]
  image_name_regex = "^Ubuntu Server 22.04 LTS 64\\w*"
}

# Get suitable instance types (2 CPU cores)
data "tencentcloud_instance_types" "types" {
  filter {
    name   = "instance-family"
    values = ["S5"] # Use S5 series - balanced performance
  }

  filter {
    name   = "zone"
    values = [data.tencentcloud_availability_zones_by_product.available.zones[0].name]
  }

  cpu_core_count   = 2
  memory_size      = 4
  exclude_sold_out = true
}

# Tencent Cloud VPC
resource "tencentcloud_vpc" "main" {
  name       = "${var.terrarium_id}-vpc"
  cidr_block = "10.5.0.0/16"
}

# Create subnet in the first available zone
resource "tencentcloud_subnet" "main" {
  name              = "${var.terrarium_id}-subnet"
  vpc_id            = tencentcloud_vpc.main.id
  cidr_block        = "10.5.1.0/24"
  availability_zone = data.tencentcloud_availability_zones_by_product.available.zones[0].name
}

# Security Group
resource "tencentcloud_security_group" "main" {
  name        = "${var.terrarium_id}-sg"
  description = "Security group for ${var.terrarium_id}"
}

# Security Group Rules
resource "tencentcloud_security_group_rule" "allow_ssh" {
  security_group_id = tencentcloud_security_group.main.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "tcp"
  port_range        = "22"
  policy            = "accept"
}

resource "tencentcloud_security_group_rule" "allow_icmp" {
  security_group_id = tencentcloud_security_group.main.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "icmp"
  policy            = "accept"
}

resource "tencentcloud_security_group_rule" "allow_traceroute" {
  security_group_id = tencentcloud_security_group.main.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "udp"
  port_range        = "33434-33534"
  policy            = "accept"
}

resource "tencentcloud_security_group_rule" "allow_all_outbound" {
  security_group_id = tencentcloud_security_group.main.id
  type              = "egress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "all"
  policy            = "accept"
}

# SSH Key Pair - Using a compliant format with underscores rather than hyphens
resource "tencentcloud_key_pair" "main" {
  key_name   = "${replace(var.terrarium_id, "-", "_")}_key"
  public_key = tls_private_key.ssh.public_key_openssh
}

# Tencent Cloud Virtual Machine (CVM)
resource "tencentcloud_instance" "main" {
  instance_name              = "${var.terrarium_id}-cvm"
  availability_zone          = data.tencentcloud_availability_zones_by_product.available.zones[0].name
  image_id                   = data.tencentcloud_images.ubuntu.images.0.image_id
  instance_type              = data.tencentcloud_instance_types.types.instance_types.0.instance_type
  system_disk_type           = "CLOUD_PREMIUM"
  system_disk_size           = 50
  vpc_id                     = tencentcloud_vpc.main.id
  subnet_id                  = tencentcloud_subnet.main.id
  hostname                   = "${var.terrarium_id}-host"
  allocate_public_ip         = true
  internet_max_bandwidth_out = 5
  orderly_security_groups    = [tencentcloud_security_group.main.id]
  key_ids                    = [tencentcloud_key_pair.main.id]

  # Add data disk
  data_disks {
    data_disk_type = "CLOUD_PREMIUM"
    data_disk_size = 50
    encrypt        = false
  }

  # Add tags
  tags = {
    Name        = "${var.terrarium_id}-cvm"
    Environment = var.terrarium_id
  }

  # User data script for instance setup
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
}
