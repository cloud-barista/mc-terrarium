# AWS Migration Testbed Module - Main Configuration

# SSH key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.terrarium_id}-vpc"
    Environment = var.terrarium_id
  }
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.terrarium_id}-subnet"
    Environment = var.terrarium_id
  }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.terrarium_id}-rtb"
    Environment = var.terrarium_id
  }
}

# Route Table Association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.terrarium_id}-igw"
  }
}

# Route for Internet Gateway
resource "aws_route" "internet_gateway" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Key Pair
resource "aws_key_pair" "main" {
  key_name   = "${var.terrarium_id}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

# Security Group - Single security group for all VMs
resource "aws_security_group" "main" {
  name        = "${var.terrarium_id}-sg"
  description = "Security group for all VMs in migration testbed"
  vpc_id      = aws_vpc.main.id

  # Default ICMP access
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "ICMP ping"
  }

  # Default traceroute UDP ports
  ingress {
    from_port   = 33434
    to_port     = 33534
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Traceroute UDP"
  }

  # SSH access from VPC CIDR and additional CIDR blocks
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat([aws_vpc.main.cidr_block], var.allowed_cidr_blocks)
    description = "SSH access from VPC CIDR and additional specified CIDR blocks"
  }

  # Allow all protocols from VPC CIDR and additional specified CIDR blocks
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = concat([aws_vpc.main.cidr_block], var.allowed_cidr_blocks)
    description = "Allow all protocols from VPC CIDR and additional specified CIDR blocks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.terrarium_id}-sg"
    Environment = var.terrarium_id
  }
}

# EC2 instances - Create individual instances for each VM
resource "aws_instance" "vms" {
  for_each = var.vm_configurations

  ami           = var.ami_id
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.main.id
  key_name      = aws_key_pair.main.key_name

  vpc_security_group_ids = [aws_security_group.main.id]

  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user-data.sh", {
    ssh_public_key = tls_private_key.ssh.public_key_openssh
    service_role   = each.value.service_role
    vm_name        = each.key
  })

  tags = {
    Name        = "${var.terrarium_id}-${each.key}"
    Environment = var.terrarium_id
    VM          = each.key
    vCPU        = each.value.vcpu
    Memory_GB   = each.value.memory_gb
    ServiceRole = each.value.service_role
  }
}
