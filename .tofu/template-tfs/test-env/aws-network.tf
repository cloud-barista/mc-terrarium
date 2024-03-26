# Define the VPC resource block
resource "aws_vpc" "test_vpc" {
  cidr_block = "192.168.64.0/18"

  tags = {
    Name = "tofu-aws-vpc"
  }
}

# Define the subnets 
resource "aws_subnet" "test_subnet_0" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "192.168.64.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "tofu-aws-subnet-0"
  }
}

resource "aws_subnet" "test_subnet_1" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "192.168.65.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = "tofu-aws-subnet-1"
  }
}

# Creating Route table for Private Subnet
resource "aws_route_table" "rt_private_1" {
  vpc_id = aws_vpc.test_vpc.id
  tags = {
    Name = "tofu-aws-vpc-rtb-subnet-1"
  }
}
resource "aws_route_table_association" "rt_associate_private_1" {
    subnet_id = aws_subnet.test_subnet_1.id
    route_table_id = aws_route_table.rt_private_1.id
}