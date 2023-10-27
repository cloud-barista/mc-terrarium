# Define the VPC resource block
resource "aws_vpc" "example_vpc" {
  cidr_block = "192.168.64.0/22"

  tags = {
    Name = "terraform-101"
  }
}

# # Define the internet gateway resource block and attach it to the VPC
# resource "aws_internet_gateway" "example_igw" {
#   vpc_id = aws_vpc.example_vpc.id
# }

# # Define the route table resource block and add a route to the internet gateway
# resource "aws_route_table" "example_rt" {
#   vpc_id = aws_vpc.example_vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.example_igw.id
#   }
# }

# Define the subnets resource blocks with the desired CIDR blocks and associate them with the route table
resource "aws_subnet" "example_subnet_1" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "192.168.64.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "example_subnet_1"
  }
}

resource "aws_subnet" "example_subnet_2" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "192.168.65.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "example_subnet_2"
  }
}

# # Associate the subnets with the route table
# resource "aws_route_table_association" "example_rta_1" {
#   subnet_id      = aws_subnet.example_subnet_1.id
#   route_table_id = aws_route_table.example_rt.id
# }

# resource "aws_route_table_association" "example_rta_2" {
#   subnet_id      = aws_subnet.example_subnet_2.id
#   route_table_id = aws_route_table.example_rt.id
# }
