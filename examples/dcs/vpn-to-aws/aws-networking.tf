# AWS VPC and Networking Resources
# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# Create subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.aws_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-subnet"
  }
}

# Create route table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  # Route to Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  # Route to DCS network via VPN
  route {
    cidr_block = var.openstack_network_cidr
    gateway_id = aws_vpn_gateway.vgw.id
  }

  tags = {
    Name = "${var.name_prefix}-rt"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Create VPN Gateway
resource "aws_vpn_gateway" "vgw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-vpn-gateway"
  }
}

# Create Customer Gateways for DCS VPN endpoints
# Both gateways use the same DCS VPN service IP but connect to different tunnels
resource "aws_customer_gateway" "cgw" {
  bgp_asn    = var.openstack_bgp_asn
  ip_address = openstack_vpnaas_service_v2.vpn.external_v4_ip
  type       = "ipsec.1"

  tags = {
    Name = "${var.name_prefix}-cgw-tunnel-1"
  }
}

# Create VPN Connections - Each uses the first tunnel only for true redundancy
resource "aws_vpn_connection" "to_dcs" {
  # vpn_gateway_id      = aws_vpn_gateway.main.id
  # customer_gateway_id = aws_customer_gateway.cgw.id
  # type                = "ipsec.1"
  # static_routes_only  = true

  # tags = {
  #   Name = "${var.name_prefix}-vpn-connection-1"
  # }

  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.cgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "${var.name_prefix}-vpn-connection"
  }

  # Tunnel 1 configuration
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase1_lifetime_seconds      = 28800

  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14] # PFS
  tunnel1_phase2_lifetime_seconds      = 3600

  tunnel1_dpd_timeout_seconds = 30
  tunnel1_dpd_timeout_action  = "restart"
  # tunnel1_preshared_key       = local.psk1

  # Tunnel 2 configuration
  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase1_lifetime_seconds      = 28800

  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]
  tunnel2_phase2_lifetime_seconds      = 3600

  tunnel2_dpd_timeout_seconds = 30
  tunnel2_dpd_timeout_action  = "restart"
  # tunnel2_preshared_key       = local.psk2
}

# Add static routes for DCS network (Required for static routing)
resource "aws_vpn_connection_route" "route_to_dcs" {
  vpn_connection_id      = aws_vpn_connection.to_dcs.id
  destination_cidr_block = var.openstack_network_cidr
}

# Enable route propagation for VPN Gateway
resource "aws_vpn_gateway_route_propagation" "prop" {
  vpn_gateway_id = aws_vpn_gateway.vgw.id
  route_table_id = aws_route_table.main.id
}

# Remove redundant aws_route resource as the route is already defined in aws_route_table.main
# resource "aws_route" "to_dcs" {
#   for_each               = toset(aws_route_table.main.*.id)
#   route_table_id         = each.value
#   destination_cidr_block = var.openstack_network_cidr
#   gateway_id             = aws_vpn_gateway.vgw.id
#   depends_on = [
#     aws_vpn_connection.to_dcs,
#     aws_vpn_connection_route.route_to_dcs
#   ]
# }

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
