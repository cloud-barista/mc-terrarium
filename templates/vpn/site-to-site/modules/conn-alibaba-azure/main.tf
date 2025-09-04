## Azure side resources/services
# Azure Local Network Gateway (require Alibaba VPN gateway info)
resource "azurerm_local_network_gateway" "alibaba_gw" {
  count = 2

  name                = "${var.name_prefix}-alibaba-side-${count.index + 1}"
  location            = var.azure_region
  resource_group_name = var.azure_resource_group_name

  gateway_address = var.alibaba_vpn_gateway_internet_ip

  bgp_settings {
    asn = var.alibaba_bgp_asn
    # Alibaba BGP peer address: Use .1 address from APIPA CIDR
    # Azure VPN Gateway uses .2, so Alibaba uses .1
    bgp_peering_address = cidrhost(var.azure_apipa_cidrs[count.index * 2], 1)
  }
}

# Azure VPN Connection
resource "azurerm_virtual_network_gateway_connection" "to_alibaba" {
  count = 2

  name                = "${var.name_prefix}-to-alibaba-${count.index + 1}"
  location            = var.azure_region
  resource_group_name = var.azure_resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = var.azure_virtual_network_gateway_id
  local_network_gateway_id   = azurerm_local_network_gateway.alibaba_gw[count.index].id
  shared_key                 = var.shared_secret

  enable_bgp = true
}

## Alibaba Cloud side resources/services
# Fetching Alibaba VPC information
data "alicloud_vpcs" "existing" {
  ids = [var.alibaba_vpc_id]
}

## Alibaba side resources/services  
# Alibaba Customer Gateway (require Azure VPN Gateway info)
resource "alicloud_vpn_customer_gateway" "azure_gw" {
  count = 2

  customer_gateway_name = "${var.name_prefix}-azure-side-gw-${count.index + 1}"
  ip_address            = var.azure_public_ip_addresses[count.index]
  asn                   = var.azure_bgp_asn # BGP ASN is mandatory when BGP is enabled
  description           = "Customer Gateway ${count.index + 1} for Azure VPN Gateway connection"

  tags = {
    Name      = "${var.name_prefix}-azure-side-gw-${count.index + 1}"
    Terrarium = var.name_prefix
  }
}

# Alibaba VPN Connections to Azure
# Note: BGP is enabled, so Customer Gateway ASN is mandatory
resource "alicloud_vpn_connection" "to_azure" {
  count = 2

  vpn_gateway_id = var.alibaba_vpn_gateway_id

  vpn_connection_name = "${var.name_prefix}-to-azure-${count.index + 1}"
  # Use specific CIDR blocks instead of 0.0.0.0/0 for better security
  local_subnet  = [data.alicloud_vpcs.existing.vpcs[0].cidr_block]
  remote_subnet = [var.azure_virtual_network_cidr]

  network_type = "public"
  # auto_config_route  = true
  effect_immediately = true
  enable_tunnels_bgp = true

  timeouts {
    create = "30m"
    delete = "30m"
  }

  depends_on = [
    alicloud_vpn_customer_gateway.azure_gw
  ]

  lifecycle {
    create_before_destroy = true
  }

  # Master tunnel configuration
  tunnel_options_specification {
    customer_gateway_id  = alicloud_vpn_customer_gateway.azure_gw[count.index].id
    role                 = "master"
    enable_dpd           = true
    enable_nat_traversal = true

    # Note - ike_mode
    # main: This mode offers higher security during negotiations.
    # aggressive: This mode supports faster negotiations and a higher success rate.
    tunnel_ike_config {
      ike_version  = "ikev2"
      psk          = var.shared_secret
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
      local_asn    = var.alibaba_bgp_asn
      tunnel_cidr  = var.azure_apipa_cidrs[count.index * 2]
      local_bgp_ip = cidrhost(var.azure_apipa_cidrs[count.index * 2], 1)
    }
  }

  # Slave tunnel configuration
  tunnel_options_specification {
    customer_gateway_id  = alicloud_vpn_customer_gateway.azure_gw[count.index].id
    role                 = "slave"
    enable_dpd           = true
    enable_nat_traversal = true

    tunnel_ike_config {
      ike_mode     = "main"
      ike_version  = "ikev2"
      psk          = var.shared_secret
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
      local_asn    = var.alibaba_bgp_asn
      tunnel_cidr  = var.azure_apipa_cidrs[count.index * 2 + 1]
      local_bgp_ip = cidrhost(var.azure_apipa_cidrs[count.index * 2 + 1], 1)
    }
  }

  tags = {
    Name      = "${var.name_prefix}-to-azure-${count.index + 1}"
    Terrarium = var.name_prefix
  }
}
