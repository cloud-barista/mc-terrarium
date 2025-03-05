## AWS side resources/services
# AWS customer gateways (require IBM VPN gateway info)
resource "aws_customer_gateway" "ibm_gw" {
  count = local.is_ibm ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-ibm-side-gw-${count.index + 1}"
  }
  bgp_asn    = var.vpn_config.target_csp.ibm.bgp_asn
  ip_address = count.index % 2 == 0 ? ibm_is_vpn_gateway.vpn_gw[0].public_ip_address : ibm_is_vpn_gateway.vpn_gw[0].public_ip_address2
  type       = "ipsec.1"
}

# AWS VPN connections for IBM Cloud
# aws_vpn_connection.to_ibm.tunnel1_cgw_inside_address - The RFC 6890 link-local address of the first VPN tunnel (Customer Gateway Side).
# aws_vpn_connection.to_ibm.tunnel1_vgw_inside_address - The RFC 6890 link-local address of the first VPN tunnel (VPN Gateway Side).
resource "aws_vpn_connection" "to_ibm" {
  count = local.is_ibm ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-to-ibm-${count.index + 1}"
  }
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.ibm_gw[count.index].id
  type                = "ipsec.1"
  static_routes_only  = true
}

# [Note] it's necessary to support static routing
# AWS VPN connection route
resource "aws_vpn_connection_route" "to_ibm" {
  count = local.is_ibm ? 2 : 0

  destination_cidr_block = var.vpn_config.target_csp.ibm.vpc_cidr
  vpn_connection_id      = aws_vpn_connection.to_ibm[count.index].id
}

## IBM Cloud side resources/services
# Fetching IBM subnets information
data "ibm_is_zones" "available" {
  count = local.is_ibm ? 1 : 0

  region = var.vpn_config.target_csp.ibm.region
}

data "ibm_is_subnets" "existing" {
  count = local.is_ibm ? 1 : 0

  vpc = var.vpn_config.target_csp.ibm.vpc_id
}

data "ibm_is_subnet" "existing" {
  count = local.is_ibm ? 1 : 0

  identifier = var.vpn_config.target_csp.ibm.subnet_id
}

locals {
  ibm_subnet_cidrs = local.is_ibm ? [for subnet in data.ibm_is_subnets.existing[0].subnets : subnet.ipv4_cidr_block] : []
  ibm_subnet_cidr  = local.is_ibm ? [data.ibm_is_subnet.existing[0].ipv4_cidr_block] : []
}

# IBM Cloud VPN Gateway
resource "ibm_is_vpn_gateway" "vpn_gw" {
  count = local.is_ibm ? 1 : 0

  name   = "${local.name_prefix}-vpn-gw-${count.index + 1}"
  subnet = var.vpn_config.target_csp.ibm.subnet_id
  mode   = "route"
}

# [Note]
# No peer gateway exists in IBM Cloud VPN Gateway
# The peer gateway refers to Customer Gateway in AWS, External Gateway in Azure, Local Network Gateway in GCP, and so on

# IBM Cloud VPN Connection
resource "ibm_is_vpn_gateway_connection" "to_aws" {
  count = local.is_ibm ? 4 : 0

  name          = "${local.name_prefix}-to-aws-${count.index + 1}"
  vpn_gateway   = ibm_is_vpn_gateway.vpn_gw[0].id
  preshared_key = count.index % 2 == 0 ? aws_vpn_connection.to_ibm[floor(count.index / 2)].tunnel1_preshared_key : aws_vpn_connection.to_ibm[floor(count.index / 2)].tunnel2_preshared_key

  # [Note] We may not use the following code.
  # In argument reference of IBM TF docs, it doesn't appear.
  # But ironically it appears in the example code.  
  # local {
  #   cidrs = local.ibm_subnet_cidrs # IBM Cloud side CIDR blocks
  # }

  peer {
    address = count.index % 2 == 0 ? aws_vpn_connection.to_ibm[floor(count.index / 2)].tunnel1_address : aws_vpn_connection.to_ibm[floor(count.index / 2)].tunnel2_address
    # [Note] We may not use the following code.
    # In argument reference of IBM TF docs, it doesn't appear.
    # But ironically it appears in the example code.
    # cidrs   = [data.aws_vpc.existing.cidr_block]
  }
}

# Fetch existing VPC routing tables
data "ibm_is_vpc_routing_tables" "existing" {
  count = local.is_ibm ? 1 : 0
  vpc   = var.vpn_config.target_csp.ibm.vpc_id
}

locals {
  # Find routing table that has our subnet attached
  target_routing_table = local.is_ibm ? [
    for rt in data.ibm_is_vpc_routing_tables.existing[0].routing_tables :
    rt if contains([for subnet in rt.subnets : subnet.id], var.vpn_config.target_csp.ibm.subnet_id)
  ][0] : null
}

# [Note] 
# Set route separately to avoid RoutingTable locking issue

# First VPN route
resource "ibm_is_vpc_routing_table_route" "vpn_route_1" {
  count = local.is_ibm ? 1 : 0

  name          = "${local.name_prefix}-to-aws-1"
  vpc           = var.vpn_config.target_csp.ibm.vpc_id
  zone          = data.ibm_is_zones.available[0].zones[0]
  routing_table = local.target_routing_table.routing_table
  destination   = data.aws_vpc.existing.cidr_block
  action        = "deliver"
  advertise     = true
  next_hop      = ibm_is_vpn_gateway_connection.to_aws[0].gateway_connection
  priority      = 1
}

# Second VPN route
resource "ibm_is_vpc_routing_table_route" "vpn_route_2" {
  count = local.is_ibm ? 1 : 0

  depends_on = [ibm_is_vpc_routing_table_route.vpn_route_1]

  name          = "${local.name_prefix}-to-aws-2"
  vpc           = var.vpn_config.target_csp.ibm.vpc_id
  zone          = data.ibm_is_zones.available[0].zones[0]
  routing_table = local.target_routing_table.routing_table
  destination   = data.aws_vpc.existing.cidr_block
  action        = "deliver"
  advertise     = true
  next_hop      = ibm_is_vpn_gateway_connection.to_aws[1].gateway_connection
  priority      = 2
}

# Third VPN route
resource "ibm_is_vpc_routing_table_route" "vpn_route_3" {
  count = local.is_ibm ? 1 : 0

  depends_on = [ibm_is_vpc_routing_table_route.vpn_route_2]

  name          = "${local.name_prefix}-to-aws-3"
  vpc           = var.vpn_config.target_csp.ibm.vpc_id
  zone          = data.ibm_is_zones.available[0].zones[0]
  routing_table = local.target_routing_table.routing_table
  destination   = data.aws_vpc.existing.cidr_block
  action        = "deliver"
  advertise     = true
  next_hop      = ibm_is_vpn_gateway_connection.to_aws[2].gateway_connection
  priority      = 3
}

# Fourth VPN route
resource "ibm_is_vpc_routing_table_route" "vpn_route_4" {
  count = local.is_ibm ? 1 : 0

  depends_on = [ibm_is_vpc_routing_table_route.vpn_route_3]

  name          = "${local.name_prefix}-to-aws-4"
  vpc           = var.vpn_config.target_csp.ibm.vpc_id
  zone          = data.ibm_is_zones.available[0].zones[0]
  routing_table = local.target_routing_table.routing_table
  destination   = data.aws_vpc.existing.cidr_block
  action        = "deliver"
  advertise     = true
  next_hop      = ibm_is_vpn_gateway_connection.to_aws[3].gateway_connection
  priority      = 4
}
