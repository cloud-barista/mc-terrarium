## AWS side resources/services
# AWS customer gateways (require Alibaba VPN gateway info)
resource "aws_customer_gateway" "alibaba_gw" {
  count = local.is_alibaba ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-alibaba-side-gw-${count.index + 1}"
  }
  bgp_asn    = var.vpn_config.target_csp.alibaba.bgp_asn
  ip_address = count.index % 2 == 0 ? alicloud_vpn_gateway.vpn_gw[0].internet_ip : alicloud_vpn_gateway.vpn_gw[0].disaster_recovery_internet_ip
  type       = "ipsec.1"
}

# AWS VPN connections for Alibaba Cloud
# aws_vpn_connection.to_alibaba.tunnel1_cgw_inside_address - The RFC 6890 link-local address of the first VPN tunnel (Customer Gateway Side).
# aws_vpn_connection.to_alibaba.tunnel1_vgw_inside_address - The RFC 6890 link-local address of the first VPN tunnel (VPN Gateway Side).
resource "aws_vpn_connection" "to_alibaba" {
  count = local.is_alibaba ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-to-alibaba-${count.index + 1}"
  }
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.alibaba_gw[count.index].id
  type                = "ipsec.1"

  # Note - Set up VPN negotiation Phase 1 (IKE negotiation) and Phase 2 (IPSec negotiation)
  # tunnel1_phase1_encryption_algorithms = ["AES128", "AES256"] # Valid values: AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16
  # tunnel1_phase1_integrity_algorithms  = ["SHA1", "SHA2-256"] # Valid values: SHA1 | SHA2-256 | SHA2-384 | SHA2-512
  # tunnel1_phase1_dh_group_numbers      = [2, 14]              # Valid values: 2 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24
  # tunnel1_phase1_lifetime_seconds      = 28800                # Valid value is between 900 and 28800
  # tunnel1_phase2_encryption_algorithms = ["AES128", "AES256"] # Valid values: AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16
  # tunnel1_phase2_integrity_algorithms  = ["SHA1", "SHA2-256"] # Valid values: SHA1 | SHA2-256 | SHA2-384 | SHA2-512
  # tunnel1_phase2_dh_group_numbers      = [2, 14]              # Valid values: 2 | 5 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24
  # tunnel1_phase2_lifetime_seconds      = 3600                 # Valid value is between 900 and 3600
  # tunnel1_ike_versions                 = ["ikev2"]            # Valid values: ikev1 | ikev2

  # tunnel2_phase1_encryption_algorithms = ["AES128", "AES256"]
  # tunnel2_phase1_integrity_algorithms  = ["SHA1", "SHA2-256"]
  # tunnel2_phase1_dh_group_numbers      = [2, 14]
  # tunnel2_phase1_lifetime_seconds      = 28800
  # tunnel2_phase2_encryption_algorithms = ["AES128", "AES256"]
  # tunnel2_phase2_integrity_algorithms  = ["SHA1", "SHA2-256"]
  # tunnel2_phase2_dh_group_numbers      = [2, 14]
  # tunnel2_phase2_lifetime_seconds      = 3600
  # tunnel2_ike_versions                 = ["ikev2"]
}

## Alibaba Cloud side resources/services
# Fetching Alibaba VPC and subnets information
data "alicloud_zones" "available" {
  count = local.is_alibaba ? 1 : 0

  available_resource_creation = "VSwitch"
}

data "alicloud_vpcs" "existing" {
  count = local.is_alibaba ? 1 : 0

  ids = [var.vpn_config.target_csp.alibaba.vpc_id]
}

data "alicloud_vswitches" "existing" {
  count  = local.is_alibaba ? 1 : 0
  vpc_id = var.vpn_config.target_csp.alibaba.vpc_id
}

locals {
  alibaba_subnet_cidrs = local.is_alibaba ? [for vswitch in data.alicloud_vswitches.existing[0].vswitches : vswitch.cidr_block] : []
}

# Alibaba Cloud VPN Gateway
resource "alicloud_vpn_gateway" "vpn_gw" {
  count = local.is_alibaba ? 1 : 0

  vpn_type                     = "Normal"
  network_type                 = "public"
  vpn_gateway_name             = "${local.name_prefix}-vpn-gw-${count.index + 1}"
  vpc_id                       = var.vpn_config.target_csp.alibaba.vpc_id
  vswitch_id                   = var.vpn_config.target_csp.alibaba.vswitch_id_1
  disaster_recovery_vswitch_id = var.vpn_config.target_csp.alibaba.vswitch_id_2
  payment_type                 = "PayAsYouGo"
  enable_ipsec                 = true
  bandwidth                    = "100" # 100Mbps (the value is 5, 10, 20, 50, 100, 200, 500, 1000)
  description                  = "VPN Gateway ${count.index + 1} for AWS to Alibaba Cloud connection"
  auto_propagate               = true
}

# Alibaba Cloud Customer Gateway (AWS VPN Gateway info required)
resource "alicloud_vpn_customer_gateway" "aws_gw" {
  count = local.is_alibaba ? 4 : 0

  customer_gateway_name = "${local.name_prefix}-aws-side-gw-${count.index + 1}"
  ip_address            = count.index % 2 == 0 ? aws_vpn_connection.to_alibaba[floor(count.index / 2)].tunnel1_address : aws_vpn_connection.to_alibaba[floor(count.index / 2)].tunnel2_address
  asn                   = count.index % 2 == 0 ? aws_vpn_connection.to_alibaba[floor(count.index / 2)].tunnel1_bgp_asn : aws_vpn_connection.to_alibaba[floor(count.index / 2)].tunnel2_bgp_asn
  description           = "Customer Gateway ${count.index + 1} for AWS VPN connection "
}

# Alibaba Cloud VPN Connection
resource "alicloud_vpn_connection" "to_aws" {
  count = local.is_alibaba ? 2 : 0

  vpn_gateway_id = alicloud_vpn_gateway.vpn_gw[0].id

  vpn_connection_name = "${local.name_prefix}-to-aws-${count.index + 1}"
  # local_subnet        = local.alibaba_subnet_cidrs
  # remote_subnet       = local.aws_subnet_cidrs
  local_subnet  = [data.alicloud_vpcs.existing[0].vpcs[0].cidr_block]
  remote_subnet = [data.aws_vpc.existing.cidr_block]

  network_type = "public"
  # auto_config_route  = true
  enable_tunnels_bgp = true
  effect_immediately = true

  tunnel_options_specification {
    customer_gateway_id  = alicloud_vpn_customer_gateway.aws_gw[count.index * 2].id
    role                 = "master"
    enable_dpd           = true
    enable_nat_traversal = true

    # Note - ike_mode
    # main: This mode offers higher security during negotiations.
    # aggressive: This mode supports faster negotiations and a higher success rate.
    tunnel_ike_config {
      ike_version  = "ikev2"
      psk          = aws_vpn_connection.to_alibaba[count.index].tunnel1_preshared_key
      ike_auth_alg = "sha1" # Valid values: md5, sha1, sha2
      ike_enc_alg  = "aes"  # Default value: aes (which is aes128) / Valid values: aes, aes192, aes256, des, and 3des
      ike_lifetime = 86400
      ike_pfs      = "group2" # Valid values: group1, group2, group5, and group14. Default value: group2.
      ike_mode     = "main"
    }

    tunnel_ipsec_config {
      ipsec_auth_alg = "sha1" # Default value: md5 / Valid values: md5, sha1, sha256, sha384, and sha512.
      ipsec_enc_alg  = "aes"  # Default value: aes (which is aes128) / Valid values: aes, aes192, aes256, des, and 3des
      ipsec_lifetime = 3600
      ipsec_pfs      = "group2" # Valid values: disabled, group1, group2, group5, and group14. Default value: group2.
    }

    tunnel_bgp_config {
      local_asn    = var.vpn_config.target_csp.alibaba.bgp_asn
      local_bgp_ip = aws_vpn_connection.to_alibaba[count.index].tunnel1_cgw_inside_address
      tunnel_cidr  = cidrsubnet("${aws_vpn_connection.to_alibaba[count.index].tunnel1_cgw_inside_address}/30", 0, 0)
    }

  }

  tunnel_options_specification {
    customer_gateway_id  = alicloud_vpn_customer_gateway.aws_gw[count.index * 2 + 1].id
    role                 = "slave"
    enable_dpd           = true
    enable_nat_traversal = true

    tunnel_ike_config {
      ike_mode     = "main"
      ike_version  = "ikev2"
      psk          = aws_vpn_connection.to_alibaba[count.index].tunnel2_preshared_key
      ike_auth_alg = "sha1" # Valid values: md5, sha1, sha2
      ike_enc_alg  = "aes"  # Default value: aes / Valid values: aes, aes192, aes256, des, and 3des
      ike_lifetime = 86400
      ike_pfs      = "group2" # Valid values: group1, group2, group5, and group14. Default value: group2.
    }

    tunnel_ipsec_config {
      ipsec_auth_alg = "sha1" # Default value: md5 / Valid values: md5, sha1, sha256, sha384, and sha512.
      ipsec_enc_alg  = "aes"  # Default value: aes (which is aes128) / Valid values: aes, aes192, aes256, des, and 3des
      ipsec_lifetime = 3600
      ipsec_pfs      = "group2" # Valid values: disabled, group1, group2, group5, and group14. Default value: group2.
    }

    tunnel_bgp_config {
      local_asn    = var.vpn_config.target_csp.alibaba.bgp_asn
      local_bgp_ip = aws_vpn_connection.to_alibaba[count.index].tunnel2_cgw_inside_address
      tunnel_cidr  = cidrsubnet("${aws_vpn_connection.to_alibaba[count.index].tunnel2_cgw_inside_address}/30", 0, 0)
    }
  }
}

# Add data source for Alibaba route tables
data "alicloud_route_tables" "existing" {
  count  = local.is_alibaba ? 1 : 0
  vpc_id = var.vpn_config.target_csp.alibaba.vpc_id
}

# IMPORTNANT: REQUIRE Alibaba side route table configuration
# Alibaba side route table configuration
resource "alicloud_route_entry" "vpn_routes" {
  count = local.is_alibaba ? 1 : 0

  route_table_id        = data.alicloud_route_tables.existing[0].ids[0]
  destination_cidrblock = data.aws_vpc.existing.cidr_block
  nexthop_type          = "VpnGateway"
  nexthop_id            = alicloud_vpn_gateway.vpn_gw[0].id
}
