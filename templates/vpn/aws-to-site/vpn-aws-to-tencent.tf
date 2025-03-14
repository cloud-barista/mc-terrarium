## AWS side resources/services
# AWS customer gateways (require Tencent VPN gateway info)
resource "aws_customer_gateway" "tencent_gw" {
  count = local.is_tencent ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-tencent-side-gw-${count.index + 1}"
  }
  bgp_asn    = var.vpn_config.target_csp.tencent.bgp_asn
  ip_address = tencentcloud_vpn_gateway.vpn_gw[count.index].public_ip_address
  type       = "ipsec.1"
}

# AWS VPN connections for Tencent Cloud
# aws_vpn_connection.to_tencent.tunnel1_cgw_inside_address - The RFC 6890 link-local address of the first VPN tunnel (Customer Gateway Side).
# aws_vpn_connection.to_tencent.tunnel1_vgw_inside_address - The RFC 6890 link-local address of the first VPN tunnel (VPN Gateway Side).
resource "aws_vpn_connection" "to_tencent" {
  count = local.is_tencent ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-to-tencent-${count.index + 1}"
  }
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.tencent_gw[count.index].id
  type                = "ipsec.1"

  ## Set custom CIDR blocks for inside tunnel addresses (Tencent's requirement)
  # note - Tencent's reserved network segment for BPG (169.254.128.0/17 - from 169.254.128.0 to 169.254.255.255).
  # When setting AWS inside IPv4 CIDR blocks to 169.254.128.0/30, 
  # AWS will use 169.254.128.1 and Tencent will use 169.254.128.2.
  tunnel1_inside_cidr = count.index == 0 ? "169.254.128.0/30" : "169.254.129.0/30"
  tunnel2_inside_cidr = count.index == 0 ? "169.254.128.4/30" : "169.254.129.4/30"

  # IKE and IPsec configuration (Phase 1 and Phase 2)
  # tunnel1_phase1_encryption_algorithms = ["AES128"] # Valid values: AES128 | AES256
  # tunnel1_phase1_integrity_algorithms  = ["SHA1"]   # Valid values: SHA1 | SHA2-256
  # tunnel1_phase1_dh_group_numbers      = [2]        # Valid values: 2 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24
  # tunnel1_phase1_lifetime_seconds      = 28800      # Valid value is between 900 and 28800
  # tunnel1_phase2_encryption_algorithms = ["AES128"] # Valid values: AES128 | AES256
  # tunnel1_phase2_integrity_algorithms  = ["SHA1"]   # Valid values: SHA1 | SHA2-256
  # tunnel1_phase2_dh_group_numbers      = [2]        # Valid values: 2 | 5 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24
  # tunnel1_phase2_lifetime_seconds      = 3600       # Valid value is between 900 and 3600
  # tunnel1_ike_versions                 = ["ikev1"]  # Valid values: ikev1 | ikev2
}

## Tencent Cloud side resources/services
# Fetching Tencent VPC and subnets information
# data "tencentcloud_vpc_instances" "existing" {
#   count = local.is_tencent ? 1 : 0

#   vpc_id = var.vpn_config.target_csp.tencent.vpc_id
# }

# data "tencentcloud_vpc_subnets" "existing" {
#   count = local.is_tencent ? 1 : 0

#   vpc_id = var.vpn_config.target_csp.tencent.vpc_id
# }

# locals {
#   tencent_subnet_cidrs = local.is_tencent ? [for subnet in data.tencentcloud_vpc_subnets.existing[0].instance_list : subnet.cidr_block] : []
# }

# Tencent Cloud VPN Gateway
resource "tencentcloud_vpn_gateway" "vpn_gw" {
  count = local.is_tencent ? 2 : 0

  name      = "${local.name_prefix}-vpn-gw-${count.index + 1}"
  vpc_id    = var.vpn_config.target_csp.tencent.vpc_id
  bandwidth = 200 # Unit: Mbps / The available values(Default: 5): 5,10,20,50,100,200,500,1000
  # type      = "CCN" # note - IPSEC may support regional VPN, and it's may not support BGP.
  bgp_asn = var.vpn_config.target_csp.tencent.bgp_asn

  # zone      = "ap-seoul-1"
  # type           = "IPSEC" # VPN gateway type(Default: IPSEC): IPSEC, SSL, CCN and SSL_CCN 
  # charge_type    = "POSTPAID_BY_HOUR" # Billing type(Default: POSTPAID_BY_HOUR): PREPAID and POSTPAID_BY_HOUR 

  tags = {
    createBy = local.name_prefix
  }
}

# Tencent Cloud Customer Gateway (AWS VPN Gateway info required)
resource "tencentcloud_vpn_customer_gateway" "aws_gw" {
  count = local.is_tencent ? 4 : 0

  name              = "${local.name_prefix}-aws-side-gw-${count.index + 1}"
  public_ip_address = count.index % 2 == 0 ? aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel1_address : aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel2_address

  tags = {
    createBy = local.name_prefix
  }
}

# Tencent Cloud VPN Connection
resource "tencentcloud_vpn_connection" "to_aws" {
  count = local.is_tencent ? 4 : 0

  name                = "${local.name_prefix}-to-aws-${count.index + 1}"
  vpc_id              = var.vpn_config.target_csp.tencent.vpc_id # Required if vpn gateway is not in CCN
  vpn_gateway_id      = tencentcloud_vpn_gateway.vpn_gw[0].id
  customer_gateway_id = tencentcloud_vpn_customer_gateway.aws_gw[count.index].id
  pre_share_key       = count.index % 2 == 0 ? aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel1_preshared_key : aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel2_preshared_key
  route_type          = "Bgp" # Valid value: STATIC, StaticRoute, Policy, Bgp
  # negotiation_type            = "active" # Optional values: active (active negotiation), passive (passive negotiation), flowTrigger (traffic negotiation)

  # IKE setting

  ike_version                = "IKEV1"    # Values: IKEV1, IKEV2. Default value is IKEV1
  ike_proto_encry_algorithm  = "3DES-CBC" # Valid values(Default: 3DES-CBC): 3DES-CBC, AES-CBC-128, AES-CBC-192, AES-CBC-256, DES-CBC, SM4, AES128GCM128, AES192GCM128, AES256GCM128,AES128GCM128, AES192GCM128, AES256GCM128.
  ike_proto_authen_algorithm = "SHA"      # Valid values(Default: MD5): MD5, SHA, SHA-256. 
  ike_exchange_mode          = "MAIN"     # Valid values(Default: MAIN): MAIN, AGGRESSIVE.
  ike_dh_group_name          = "GROUP2"   # Valid values(Default: GROUP2): GROUP1, GROUP2, GROUP5, GROUP14, and GROUP24.
  ike_sa_lifetime_seconds    = 86400      # Unit: second / The value ranges from 60 to 604800. Default value is 86400 seconds.
  ike_local_identity         = "ADDRESS"  # Valid values(Default: ADDRESS): ADDRESS, FQDN. 
  ike_local_address          = tencentcloud_vpn_gateway.vpn_gw[floor(count.index / 2)].public_ip_address
  ike_remote_identity        = "ADDRESS" # Valid values(Default: ADDRESS): ADDRESS, FQDN.
  ike_remote_address         = count.index % 2 == 0 ? aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel1_address : aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel2_address

  # IPSEC setting
  ipsec_encrypt_algorithm   = "3DES-CBC" # Valid values(Default: 3DES-CBC): 3DES-CBC, AES-CBC-128, AES-CBC-192, AES-CBC-256, DES-CBC, SM4, NULL, AES128GCM128, AES192GCM128, AES256GCM128.
  ipsec_integrity_algorithm = "SHA1"     # Valid values(Default: MD5): MD5, SHA1, SHA-256.
  ipsec_sa_lifetime_seconds = 3600       # Unit: second / Valid value ranges: [180~604800]. Default value is 3600 seconds.
  ipsec_pfs_dh_group        = "NULL"     # Valid values(Default: NULL): DH-GROUP1, DH-GROUP2, DH-GROUP5, DH-GROUP14, DH-GROUP24, NULL.
  ipsec_sa_lifetime_traffic = 1843200    # Unit: KB / The value should not be less then 2560. Default value is 1843200

  bgp_config {
    # Note - Inside tunnel addresses generated by AWS may not be used
    # due to Tencent's reserved network segment for BPG (169.254.128.0/17 - from 169.254.128.0 to 169.254.255.255).
    # aws_vpn_connection.to_tencent[x].tunnel1_cgw_inside_address,
    # aws_vpn_connection.to_tencent[x].tunnel2_cgw_inside_address,
    local_bgp_ip  = count.index % 2 == 0 ? aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel1_cgw_inside_address : aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel2_cgw_inside_address
    remote_bgp_ip = count.index % 2 == 0 ? aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel1_vgw_inside_address : aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel2_vgw_inside_address
    tunnel_cidr   = count.index % 2 == 0 ? cidrsubnet("${aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel1_cgw_inside_address}/30", 0, 0) : cidrsubnet("${aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel2_cgw_inside_address}/30", 0, 0)
  }

  enable_health_check    = true
  health_check_local_ip  = count.index % 2 == 0 ? aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel1_cgw_inside_address : aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel2_cgw_inside_address
  health_check_remote_ip = aws_vpn_connection.to_tencent[floor(count.index / 2)].tunnel1_vgw_inside_address

  tags = {
    createBy = local.name_prefix
  }
}

# # Add route table entry for Tencent VPC to route traffic to AWS VPC through the VPN
# resource "tencentcloud_route_table_entry" "vpn_routes" {
#   count = local.is_tencent ? 1 : 0

#   route_table_id         = data.tencentcloud_vpc_instances.existing[0].instance_list[0].default_route_table_id
#   destination_cidr_block = data.aws_vpc.existing.cidr_block
#   next_type              = "VPN"
#   next_hub               = tencentcloud_vpn_connection.to_aws[0].id

#   depends_on = [
#     tencentcloud_vpn_connection.to_aws,
#     tencentcloud_vpn_gateway.vpn_gw
#   ]
# }
