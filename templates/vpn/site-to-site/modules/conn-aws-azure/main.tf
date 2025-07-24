## AWS side resources/services
# AWS Customer Gateway (require Azure VPN Gateway info)
resource "aws_customer_gateway" "azure_gw" {
  count = 2

  tags = {
    Name = "${var.name_prefix}-azure-side-gw-${count.index + 1}"
  }
  bgp_asn    = var.azure_bgp_asn
  ip_address = var.azure_public_ip_addresses[count.index]
  type       = "ipsec.1"
}

# AWS VPN Connection with custom inside CIDR blocks (due to Azure VPN Gateway's requirement)
resource "aws_vpn_connection" "to_azure" {
  count = 2

  tags = {
    Name = "${var.name_prefix}-to-azure-${count.index + 1}"
  }
  vpn_gateway_id      = var.aws_vpn_gateway_id
  customer_gateway_id = aws_customer_gateway.azure_gw[count.index].id
  type                = "ipsec.1"

  ## Set custom CIDR blocks for inside tunnel addresses (Azure VPN Gateway's requirement)
  # When setting AWS inside IPv4 CIDR blocks to 169.254.21.0/30, 
  # AWS will use 169.254.21.1 and
  # Azure will use 169.254.21.2.

  # Example of var.azure_apipa_cidrs is ["169.254.21.0/30", "169.254.21.4/30", "169.254.22.0/30", "169.254.22.4/30"]
  tunnel1_inside_cidr = count.index % 2 == 0 ? var.azure_apipa_cidrs[0] : var.azure_apipa_cidrs[2]
  tunnel2_inside_cidr = count.index % 2 == 0 ? var.azure_apipa_cidrs[1] : var.azure_apipa_cidrs[3]
}

# Azure Local Network Gateway (require AWS VPN gateway info)
resource "azurerm_local_network_gateway" "aws_gw" {
  count = 4

  name                = "${var.name_prefix}-aws-side-${count.index + 1}"
  location            = var.azure_region
  resource_group_name = var.azure_resource_group_name

  gateway_address = count.index % 2 == 0 ? aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel1_address : aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel2_address

  bgp_settings {
    asn                 = count.index % 2 == 0 ? aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel1_bgp_asn : aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel2_bgp_asn
    bgp_peering_address = count.index % 2 == 0 ? aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel1_vgw_inside_address : aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel2_vgw_inside_address
  }
}

# Azure VPN Connection 
resource "azurerm_virtual_network_gateway_connection" "to_aws" {
  count = 4

  name                = "${var.name_prefix}-to-aws-${count.index + 1}"
  location            = var.azure_region
  resource_group_name = var.azure_resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = var.azure_virtual_network_gateway_id
  local_network_gateway_id   = azurerm_local_network_gateway.aws_gw[count.index].id
  shared_key                 = count.index % 2 == 0 ? aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel1_preshared_key : aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel2_preshared_key

  enable_bgp = true
}
