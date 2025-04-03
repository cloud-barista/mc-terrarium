# vpc-aws.tf
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.terrarium_id}-vpc"
    Environment = var.terrarium_id
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.terrarium_id}-subnet"
    Environment = var.terrarium_id
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.terrarium_id}-rtb"
    Environment = var.terrarium_id
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# AWS Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.terrarium_id}-igw"
  }
}

# AWS route rule for Internet Gateway
resource "aws_route" "internet_gateway" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# AWS Key Pair
resource "aws_key_pair" "main" {
  key_name   = "${var.terrarium_id}-key"
  public_key = var.public_key
}

# AWS Security Group
resource "aws_security_group" "main" {
  name        = "${var.terrarium_id}-sg"
  description = "Allow SSH and ICMP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 33434
    to_port     = 33534
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.terrarium_id}-sg"
  }
}


# AWS EC2 instance
resource "aws_instance" "main" {
  ami           = "ami-0f3a440bbcff3d043" # Ubuntu 22.04 LTS in Seoul
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.main.id
  key_name      = aws_key_pair.main.key_name

  vpc_security_group_ids = [aws_security_group.main.id]

  associate_public_ip_address = true

  tags = {
    Name = "${var.terrarium_id}-ec2"
  }
}
