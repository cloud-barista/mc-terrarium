# Define the required version of Terraform and the providers that will be used in the project
terraform {
  # Required Tofu version
  required_version = "~>1.8.3"

  required_providers {
    # AWS provider is specified with its source and version
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
  }
}

# Provider block for AWS specifies the configuration for the provider
provider "aws" {
  region = "ap-northeast-2"
}

# Define the VPC resource block
resource "aws_vpc" "secure_testbed" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "secure-testbed"
  }
}

# Define the subnets resource blocks with the desired CIDR blocks and associate them with the route table
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.secure_testbed.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2a"
  tags = {
    Name = "secure-testbed-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.secure_testbed.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-2b"
  tags = {
    Name = "secure-testbed-private-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.secure_testbed.id
  tags = {
    Name = "secure-testbed-igw"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.secure_testbed.id
  tags = {
    Name = "public-rtb"
  }
}
# Add default routing table for the public subnet
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
# Connect the route table to the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  tags = {
    Name = "nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "nat-gateway"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.secure_testbed.id
  tags = {
    Name = "private-rtb"
  }
}
# Add a routing table for the private subnet
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security group for the public subnet
resource "aws_security_group" "allow_ssh_and_wg" {
  name        = "allow-ssh-and-wg"
  description = "Allow TLS and Wireguard inbound traffic"
  vpc_id      = aws_vpc.secure_testbed.id

  ingress {
    description = "Allow SSH from the office"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["129.254.0.0/16"]
  }

  ingress {
    description = "WireGuard UDP traffic"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["129.254.0.0/16"]
  }

  ingress {
    description = "Allow TCP port for WireGuard Easy Web UI"
    from_port   = 51821
    to_port     = 51821
    protocol    = "tcp"
    cidr_blocks = ["129.254.0.0/16"]
  }

  ingress {
    description = "Allow TCP port for ngrok web interface"
    from_port   = 4040
    to_port     = 4040
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow ping in VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow-ssh-and-wg"
  }
}


# Security Group for Private Subnet
resource "aws_security_group" "allow_ssh_from_public_subnet" {
  vpc_id = aws_vpc.secure_testbed.id
  name   = "allow-ssh-from-public-subnet"

  ingress {
    description = "Allow traffic in VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow ping in VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow CB-Tumblebug API traffic"
    from_port   = 1323
    to_port     = 1323
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow CB-MapUI traffic"
    from_port   = 1324
    to_port     = 1324
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh-from-public-subnet"
  }
}

# Create an instance in the public subnet
resource "aws_instance" "wg-server" {
  ami                    = "ami-042e76978adeb8c48" # Ubuntu 22.04 LTS
  instance_type          = "t3.medium"
  key_name               = "secure-testbed-keypair"
  vpc_security_group_ids = [aws_security_group.allow_ssh_and_wg.id]
  availability_zone      = "ap-northeast-2a"
  subnet_id              = aws_subnet.public.id
  user_data              = file("./init.sh")

  # Set source/destination check
  source_dest_check = false

  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "secure-wg-svr"
  }
}

# Create an instance in the private subnet
resource "aws_instance" "secure-server" {
  ami                    = "ami-042e76978adeb8c48" # Ubuntu 22.04 LTS
  instance_type          = "t3.medium"
  key_name               = "secure-testbed-keypair"
  vpc_security_group_ids = [aws_security_group.allow_ssh_from_public_subnet.id]
  availability_zone      = "ap-northeast-2b"
  subnet_id              = aws_subnet.private.id


  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "secure-svr"
  }
}
