## Azure side resources/services
# Azure Virtual Network
data "azurerm_virtual_network" "existing" {

  name                = var.vpn_config.azure.virtual_network_name
  resource_group_name = var.vpn_config.azure.resource_group_name
}

# Gateway Subnet (Azure requirement: "GatewaySubnet" is required for VPN Gateway)
resource "azurerm_subnet" "gateway" {

  name                 = "GatewaySubnet"
  resource_group_name  = var.vpn_config.azure.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.existing.name
  address_prefixes     = [var.vpn_config.azure.gateway_subnet_cidr]
}

# Public IPs for Azure VPN Gateway
resource "azurerm_public_ip" "pub_ip" {
  count = 2 # 2 Public IPs for Active-Active configuration

  name                = "${var.vpn_config.terrarium_id}-vpn-ip-${count.index + 1}"
  location            = var.vpn_config.azure.region
  resource_group_name = var.vpn_config.azure.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"] # Availability zones
}

# Azure VPN Gateway with pre-allocated APIPA addresses
resource "azurerm_virtual_network_gateway" "vpn_gw" {

  name                = "${var.vpn_config.terrarium_id}-vpn-gateway"
  location            = var.vpn_config.azure.region
  resource_group_name = var.vpn_config.azure.resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = var.vpn_config.azure.vpn_sku

  ip_configuration {
    name                          = "${var.vpn_config.terrarium_id}-gateway-config-1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pub_ip[0].id
    subnet_id                     = azurerm_subnet.gateway.id
  }

  ip_configuration {
    name                          = "${var.vpn_config.terrarium_id}-gateway-config-2"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pub_ip[1].id
    subnet_id                     = azurerm_subnet.gateway.id
  }

  # https://learn.microsoft.com/en-us/azure/vpn-gateway/bgp-howto
  # The Azure APIPA BGP IP address field is optional. (APIPA: Automatic Private IP Addressing) 
  # If your on-premises VPN devices use APIPA address for BGP, 
  # you must select an address from the Azure-reserved APIPA address range for VPN, 
  # which is from 169.254.21.0 to 169.254.22.255.
  bgp_settings {
    asn = var.vpn_config.azure.bgp_asn
    peering_addresses {
      ip_configuration_name = "${var.vpn_config.terrarium_id}-gateway-config-1"
      apipa_addresses = [
        # Dynamic APIPA address selection based on configured peering connections
        # Uses first available connection: AWS > GCP > Alibaba > Tencent > IBM
        for i, cidr in coalesce(
          var.vpn_config.azure.bgp_peering_cidrs.to_aws,
          var.vpn_config.azure.bgp_peering_cidrs.to_gcp,
          var.vpn_config.azure.bgp_peering_cidrs.to_alibaba,
          var.vpn_config.azure.bgp_peering_cidrs.to_tencent,
          var.vpn_config.azure.bgp_peering_cidrs.to_ibm,
          ["169.254.21.0/30", "169.254.21.4/30"] # Fallback CIDRs
        ) : cidrhost(cidr, 2) if i % 2 == 0
        # Azure uses .2 addresses: "169.254.21.2", "169.254.22.2"
        # Peer CSP uses .1 addresses: "169.254.21.1", "169.254.22.1"
      ]
    }
    peering_addresses {
      ip_configuration_name = "${var.vpn_config.terrarium_id}-gateway-config-2"
      apipa_addresses = [
        # Dynamic APIPA address selection based on configured peering connections
        # Uses first available connection: AWS > GCP > Alibaba > Tencent > IBM
        for i, cidr in coalesce(
          var.vpn_config.azure.bgp_peering_cidrs.to_aws,
          var.vpn_config.azure.bgp_peering_cidrs.to_gcp,
          var.vpn_config.azure.bgp_peering_cidrs.to_alibaba,
          var.vpn_config.azure.bgp_peering_cidrs.to_tencent,
          var.vpn_config.azure.bgp_peering_cidrs.to_ibm,
          ["169.254.21.0/30", "169.254.21.4/30"] # Fallback CIDRs
        ) : cidrhost(cidr, 2) if i % 2 == 1
        # Azure uses .2 addresses: "169.254.21.6", "169.254.22.6"
        # Peer CSP uses .1 addresses: "169.254.21.5", "169.254.22.5"
      ]
    }
  }
}
