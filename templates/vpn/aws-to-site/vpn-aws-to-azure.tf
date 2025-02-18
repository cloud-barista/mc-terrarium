
# AWS Customer Gateway 생성 (Azure Gateway IP 사용)
resource "aws_customer_gateway" "azure_gw" {
  count = local.is_azure ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-azure-cgw-${count.index + 1}"
  }
  bgp_asn    = var.vpn_config.target_csp.azure.bgp_asn
  ip_address = azurerm_public_ip.vpn[count.index].ip_address
  type       = "ipsec.1"
}

# AWS VPN Connection 생성
resource "aws_vpn_connection" "conn_to_azure" {
  count = local.is_azure ? 2 : 0

  tags = {
    Name = "${local.name_prefix}-to-azure-${count.index + 1}"
  }
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.azure_gw[count.index].id
  type                = "ipsec.1"
}

# vpn-aws-to-azure.tf

# Azure Virtual Network 참조
data "azurerm_virtual_network" "vnet" {
  count               = local.is_azure ? 1 : 0
  name                = var.vpn_config.target_csp.azure.virtual_network_name
  resource_group_name = var.vpn_config.target_csp.azure.resource_group_name
}

# Gateway Subnet 생성
resource "azurerm_subnet" "gateway" {
  count                = local.is_azure ? 1 : 0
  name                 = "GatewaySubnet" # Azure 요구사항: VPN Gateway를 위한 서브넷은 반드시 이 이름이어야 함
  resource_group_name  = var.vpn_config.target_csp.azure.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet[0].name
  address_prefixes     = [var.vpn_config.target_csp.azure.gateway_subnet_cidr]
}

# Azure VPN Gateway를 위한 Public IP
resource "azurerm_public_ip" "vpn" {
  count               = local.is_azure ? 2 : 0 # Active-Active 구성을 위해 2개 필요
  name                = "${local.name_prefix}-vpn-ip-${count.index + 1}"
  location            = var.vpn_config.target_csp.azure.region
  resource_group_name = var.vpn_config.target_csp.azure.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"] # 가용성 존 지원
}

# Azure VPN Gateway 생성
resource "azurerm_virtual_network_gateway" "vpn" {
  count               = local.is_azure ? 1 : 0
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
    subnet_id                     = azurerm_subnet.gateway[0].id
    public_ip_address_id          = azurerm_public_ip.vpn[0].id
  }

  ip_configuration {
    name                          = "${local.name_prefix}-gateway-config-2"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway[0].id
    public_ip_address_id          = azurerm_public_ip.vpn[1].id
  }

  bgp_settings {
    asn = var.vpn_config.target_csp.azure.bgp_asn
    peering_addresses {
      ip_configuration_name = "${local.name_prefix}-gateway-config-1"
      apipa_addresses       = ["169.254.21.1"]
    }
    peering_addresses {
      ip_configuration_name = "${local.name_prefix}-gateway-config-2"
      apipa_addresses       = ["169.254.22.1"]
    }
  }
}



# Azure Local Network Gateway 생성 (AWS VPN 정보 사용)
resource "azurerm_local_network_gateway" "aws" {
  count               = local.is_azure ? 2 : 0
  name                = "${local.name_prefix}-aws-local-${count.index + 1}"
  location            = var.vpn_config.target_csp.azure.region
  resource_group_name = var.vpn_config.target_csp.azure.resource_group_name

  gateway_address = aws_vpn_connection.conn_to_azure[count.index].tunnel1_address

  bgp_settings {
    asn                 = aws_vpn_gateway.vpn_gw.amazon_side_asn
    bgp_peering_address = aws_vpn_connection.conn_to_azure[count.index].tunnel1_vgw_inside_address
  }
}

# Azure VPN Connection 생성
resource "azurerm_virtual_network_gateway_connection" "aws" {
  count               = local.is_azure ? 2 : 0
  name                = "${local.name_prefix}-to-aws-${count.index + 1}"
  location            = var.vpn_config.target_csp.azure.region
  resource_group_name = var.vpn_config.target_csp.azure.resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn[0].id
  local_network_gateway_id   = azurerm_local_network_gateway.aws[count.index].id
  shared_key                 = var.vpn_config.target_csp.azure.shared_key

  enable_bgp = true
}
