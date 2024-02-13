# Define the VPC resource block
# resource "aws_vpc" "my-aws-vpc" {
#   cidr_block = "192.168.64.0/18"

#   tags = {
#     Name = "my-aws-vpc-name"
#   }
# }

# Define the subnets resource blocks with the desired CIDR blocks and associate them with the route table
# resource "aws_subnet" "my-aws-subnet-1" {
#   vpc_id                  = aws_vpc.my-aws-vpc.id
#   cidr_block              = "192.168.64.0/24"
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "my-aws-subnet-1-name"
#   }
# }

# resource "aws_subnet" "my-aws-subnet-2" {
#   vpc_id                  = aws_vpc.my-aws-vpc.id
#   cidr_block              = "192.168.65.0/24"
#   map_public_ip_on_launch = false
#   tags = {
#     Name = "my-aws-subnet-2-name"
#   }
# }

##################################################################

# Create a VPN Gateway
resource "aws_vpn_gateway" "my-aws-vpn-gateway" {
  tags = {
    Name = "my-aws-vpn-gateway-name"
  }
  vpc_id = var.my-imported-aws-vpc-id
}

# Create a Customer Gateway
resource "aws_customer_gateway" "my-aws-cgw-1" {
  tags = {
    Name = "my-aws-cgw-1-name"
  }
  bgp_asn    = google_compute_router.my-gcp-router-main.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.vpn_interfaces[0].ip_address
  type       = "ipsec.1"
}

# Create a Customer Gateway
resource "aws_customer_gateway" "my-aws-cgw-2" {
  tags = {
    Name = "my-aws-cgw-2-name"
  }
  bgp_asn    = google_compute_router.my-gcp-router-main.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.vpn_interfaces[1].ip_address
  type       = "ipsec.1"
}

##################################################################

# Create a VPN Connection between the VPN Gateway and the Customer Gateway
resource "aws_vpn_connection" "my-aws-cx-1" {
  tags = {
    Name = "my-aws-cx-1-name"
  }
  vpn_gateway_id      = aws_vpn_gateway.my-aws-vpn-gateway.id
  customer_gateway_id = aws_customer_gateway.my-aws-cgw-1.id
  type                = "ipsec.1"
}

resource "aws_vpn_connection" "my-aws-cx-2" {
  tags = {
    Name = "my-aws-cx-2-name"
  }
  vpn_gateway_id      = aws_vpn_gateway.my-aws-vpn-gateway.id
  customer_gateway_id = aws_customer_gateway.my-aws-cgw-2.id
  type                = "ipsec.1"
}

##################################################################
# [NOTE] If a Route Table and Route Table Association with a subnet already exist, 
#        the following code will not work. we have to find a way 
#        to import them into the state file.

# Create a Route Table and add a route to the VPN Connection
resource "aws_route_table" "my-aws-rt" {
  tags = {
    Name = "my-aws-rt-name"
  }
  
  vpc_id = var.my-imported-aws-vpc-id
  propagating_vgws = [aws_vpn_gateway.my-aws-vpn-gateway.id]
}

# Create a Route Table Association between the Route Table and the Subnet
resource "aws_route_table_association" "my-aws-rta-1" {
  # count = 3
  # subnet_id = element(aws_subnet.main.*.id, count.index)
  subnet_id = var.my-imported-aws-subnet-id
  route_table_id = aws_route_table.my-aws-rt.id
}
