## AWS side resources/services
# AWS customer gateways (require Alibaba VPN gateway info)
resource "aws_customer_gateway" "alibaba_gw" {
  count = local.is_alibaba ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-alibaba-side-gw-${count.index + 1}"
  }
  bgp_asn    = var.vpn_config.target_csp.alibaba.bgp_asn
  ip_address = alicloud_vpn_gateway.vpn_gw[count.index].internet_ip
  type       = "ipsec.1"
}

# AWS VPN connections for GCP
# aws_vpn_connection.to_gcp.tunnel1_cgw_inside_address - The RFC 6890 link-local address of the first VPN tunnel (Customer Gateway Side).
# aws_vpn_connection.to_gcp.tunnel1_vgw_inside_address - The RFC 6890 link-local address of the first VPN tunnel (VPN Gateway Side).
resource "aws_vpn_connection" "to_alibaba" {
  count = local.is_alibaba ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-to-alibaba-${count.index + 1}"
  }
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.alibaba_gw[count.index].id
  type                = "ipsec.1"
}

## Alibaba Cloud side resources/services
# VPC information
data "alicloud_vpcs" "selected" {
  count = local.is_alibaba ? 1 : 0

  ids = [var.vpn_config.target_csp.alibaba.vpc_id]
}

# Alibaba Cloud VPN Gateway
resource "alicloud_vpn_gateway" "vpn_gw" {
  count = local.is_alibaba ? 2 : 0

  vpn_gateway_name = "${local.name_prefix}-vpn-gw-${count.index + 1}"
  vpc_id           = var.vpn_config.target_csp.alibaba.vpc_id
  # vswitch_id  = var.alicloud_vpc.vswitch_id
  bandwidth      = "100" # 100Mbps (the value is 5, 10, 20, 50, 100, 200, 500, 1000)
  enable_ssl     = false
  description    = "VPN Gateway ${count.index + 1} for AWS to Alibaba Cloud connection"
  auto_propagate = true
}

# Alibaba Cloud Customer Gateway (AWS VPN Gateway info required)
resource "alicloud_vpn_customer_gateway" "aws_gw" {
  count = local.is_alibaba ? 4 : 0

  customer_gateway_name = "${local.name_prefix}-aws-side-gw-${count.index + 1}"
  ip_address            = count.index % 2 == 0 ? aws_vpn_connection.to_alibaba[floor(count.index / 2)].tunnel1_address : aws_vpn_connection.to_alibaba[floor(count.index / 2)].tunnel1_address
  description           = "Customer Gateway ${count.index + 1} for AWS VPN connection "
}

# Alibaba Cloud VPN Connection
resource "alicloud_vpn_connection" "to_aws" {
  count = local.is_alibaba ? 4 : 0

  vpn_connection_name = "${local.name_prefix}-to-aws-${count.index + 1}"
  vpn_gateway_id      = alicloud_vpn_gateway.vpn_gw[floor(count.index / 2)].id
  customer_gateway_id = alicloud_vpn_customer_gateway.aws_gw[count.index].id
  local_subnet        = [data.alicloud_vpcs.selected.cidr_block] # Alibaba VPC CIDR
  remote_subnet       = [data.aws_vpc.selected.cidr_block]       # AWS VPC CIDR

  enable_tunnels_bgp = true
  effect_immediately = true
  tunnel_options_specification {
    tunnel_ike_config {
      ike_version  = "ikev1"
      ike_mode     = "main"
      ike_enc_alg  = "aes"
      ike_auth_alg = "sha1"
      ike_lifetime = 86400
      psk          = count.index % 2 == 0 ? aws_vpn_connection.to_alibaba[floor(count.index / 2)].tunnel1_preshared_key : aws_vpn_connection.to_alibaba[floor(count.index / 2)].tunnel2_preshared_key
      ike_pfs      = "group2"
      # ike_local_id = 
      # ike_remote_id =
    }
    tunnel_ipsec_config {
      ipsec_enc_alg  = "aes"
      ipsec_auth_alg = "sha1"
      ipsec_pfs      = "group2"
      ipsec_lifetime = 86400
    }
    tunnel_bgp_config {
      local_asn    = var.vpn_config.target_csp.alibaba.bgp_asn
      local_bgp_ip = count.index % 2 == 0 ? aws_vpn_connection.to_alibaba[floor(count.index / 2)].tunnel1_cgw_inside_address : aws_vpn_connection.to_alibaba[floor(count.index / 2)].tunnel2_cgw_inside_address
      tunnel_cidr  = count.index % 2 == 0 ? cidrsubnet("${aws_vpn_connection.to_alibaba[index].tunnel1_cgw_inside_address}/30", 0, 0) : cidrsubnet("${aws_vpn_connection.to_alibaba[index].tunnel2_cgw_inside_address}/30", 0, 0)
    }
  }
  # ike_config {
  #   ike_version  = "ikev1"
  #   ike_mode     = "main"
  #   ike_enc_alg  = "aes"
  #   ike_auth_alg = "sha1"
  #   ike_lifetime = 86400
  #   psk          = count.index % 2 == 0 ? aws_vpn_connection.to_alibaba[floor(count.index / 2)].tunnel1_preshared_key : aws_vpn_connection.to_alibaba[floor(count.index / 2)].tunnel2_preshared_key
  #   ike_pfs      = "group2"
  #   # ike_local_id = 
  #   # ike_remote_id =
  # }
  # ipsec_config {
  #   ipsec_enc_alg  = "aes"
  #   ipsec_auth_alg = "sha1"
  #   ipsec_pfs      = "group2"
  #   ipsec_lifetime = 86400
  # }
}

