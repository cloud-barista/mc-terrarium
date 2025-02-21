## AWS side resources/services
# AWS Customer Gateway (require Azure VPN Gateway info)
resource "aws_customer_gateway" "azure_gw" {
  count = local.is_azure ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-azure-side-gw-${count.index + 1}"
  }
  bgp_asn    = var.vpn_config.target_csp.azure.bgp_asn
  ip_address = azurerm_public_ip.vpn[count.index].ip_address
  type       = "ipsec.1"
}

# AWS VPN Connection
resource "aws_vpn_connection" "to_azure" {
  count = local.is_azure ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-to-azure-${count.index + 1}"
  }
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.azure_gw[count.index].id
  type                = "ipsec.1"
}


## Azure side resources/services
# Azure Virtual Network
data "azurerm_virtual_network" "vnet" {
  count = local.is_azure ? 1 : 0

  name                = var.vpn_config.target_csp.azure.virtual_network_name
  resource_group_name = var.vpn_config.target_csp.azure.resource_group_name
}

# Gateway Subnet (Azure requirement: "GatewaySubnet" is required for VPN Gateway)
resource "azurerm_subnet" "gateway" {
  count                = local.is_azure ? 1 : 0
  name                 = "GatewaySubnet"
  resource_group_name  = var.vpn_config.target_csp.azure.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet[0].name
  address_prefixes     = [var.vpn_config.target_csp.azure.gateway_subnet_cidr]
}

# Public IPs for Azure VPN Gateway
resource "azurerm_public_ip" "vpn" {
  count = local.is_azure ? 2 : 0 # 2 Public IPs for Active-Active configuration

  name                = "${local.name_prefix}-vpn-ip-${count.index + 1}"
  location            = var.vpn_config.target_csp.azure.region
  resource_group_name = var.vpn_config.target_csp.azure.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"] # Availability zones
}

# Azure VPN Gateway
resource "azurerm_virtual_network_gateway" "vpn" {
  count = local.is_azure ? 1 : 0

  name                = "${local.name_prefix}-vpn-gateway"
  location            = var.vpn_config.target_csp.azure.region
  resource_group_name = var.vpn_config.target_csp.azure.resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = var.vpn_config.target_csp.azure.vpn_sku

  ip_configuration {
    name                          = "${local.name_prefix}-gateway-config-1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vpn[0].id
    subnet_id                     = azurerm_subnet.gateway[0].id
  }

  ip_configuration {
    name                          = "${local.name_prefix}-gateway-config-2"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vpn[1].id
    subnet_id                     = azurerm_subnet.gateway[0].id
  }

  bgp_settings {
    asn = var.vpn_config.target_csp.azure.bgp_asn
    peering_addresses {
      ip_configuration_name = "${local.name_prefix}-gateway-config-1"
      # apipa_addresses       = ["169.254.21.1"]
      apipa_addresses = [
        aws_vpn_connection.to_azure[0].tunnel1_cgw_inside_address,
        aws_vpn_connection.to_azure[0].tunnel2_cgw_inside_address
      ]
    }
    peering_addresses {
      ip_configuration_name = "${local.name_prefix}-gateway-config-2"
      # apipa_addresses       = ["169.254.22.1"]
      apipa_addresses = [
        aws_vpn_connection.to_azure[1].tunnel1_cgw_inside_address,
        aws_vpn_connection.to_azure[1].tunnel2_cgw_inside_address
      ]
    }
  }
}

# Azure Local Network Gateway (require AWS VPN gateway info)
resource "azurerm_local_network_gateway" "aws_gw" {
  count = local.is_azure ? 4 : 0

  name                = "${local.name_prefix}-aws-side-${count.index + 1}"
  location            = var.vpn_config.target_csp.azure.region
  resource_group_name = var.vpn_config.target_csp.azure.resource_group_name

  gateway_address = count.index % 2 == 0 ? aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel1_address : aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel2_address

  bgp_settings {
    asn                 = aws_vpn_gateway.vpn_gw.amazon_side_asn
    bgp_peering_address = count.index % 2 == 0 ? aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel1_vgw_inside_address : aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel2_vgw_inside_address
  }
}

# Azure VPN Connection 
resource "azurerm_virtual_network_gateway_connection" "to_aws" {
  count = local.is_azure ? 4 : 0

  name                = "${local.name_prefix}-to-aws-${count.index + 1}"
  location            = var.vpn_config.target_csp.azure.region
  resource_group_name = var.vpn_config.target_csp.azure.resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn[0].id
  local_network_gateway_id   = azurerm_local_network_gateway.aws_gw[count.index].id
  shared_key                 = count.index % 2 == 0 ? aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel1_preshared_key : aws_vpn_connection.to_azure[floor(count.index / 2)].tunnel2_preshared_key

  enable_bgp = true
}
