
# Create a virtual network
resource "azurerm_virtual_network" "my-azure-vnet" {
  name                = "my-azure-vnet-name"
  address_space       = ["192.168.128.0/18"]
  location            = azurerm_resource_group.my-azure-resource-group.location
  resource_group_name = azurerm_resource_group.my-azure-resource-group.name
}

# Create subnets
resource "azurerm_subnet" "my-azure-subnet" {
  name                 = "my-azure-subnet-1"
  resource_group_name  = azurerm_resource_group.my-azure-resource-group.name
  virtual_network_name = azurerm_virtual_network.my-azure-vnet.name
  address_prefixes     = ["192.168.128.0/24"]
}

resource "azurerm_subnet" "my-azure-gw-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.my-azure-resource-group.name
  virtual_network_name = azurerm_virtual_network.my-azure-vnet.name
  address_prefixes     = ["192.168.129.0/24"]
}

# Create public IP addresses
resource "azurerm_public_ip" "my-azure-public-ip-1" {
  name                = "my-azure-public-ip-1-name"
  location            = var.my-azure-region
  resource_group_name = azurerm_resource_group.my-azure-resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = contains(var.my-azure-vpn-allowed-az-skus, var.my-azure-vpn-sku) ? ["1", "2", "3"] : []
}

resource "azurerm_public_ip" "my-azure-public-ip-2" {
  name                = "my-azure-public-ip-2-name"
  location            = var.my-azure-region
  resource_group_name = azurerm_resource_group.my-azure-resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = contains(var.my-azure-vpn-allowed-az-skus, var.my-azure-vpn-sku) ? ["1", "2", "3"] : []
}

# Create Azure VPN Gateway and connections
resource "azurerm_virtual_network_gateway" "my-azure-vpn-gateway" {
  name                = "my-azure-vpn-gateway-name"
  location            = var.my-azure-region
  resource_group_name = azurerm_resource_group.my-azure-resource-group.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = var.my-azure-vpn-sku

  ip_configuration {
    name                          = "vnetGatewayConfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.my-azure-gw-subnet.id
    public_ip_address_id          = azurerm_public_ip.my-azure-public-ip-1.id
  }

  ip_configuration {
    name                          = "vnetGatewayConfig2"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.my-azure-gw-subnet.id
    public_ip_address_id          = azurerm_public_ip.my-azure-public-ip-2.id
  }

  bgp_settings {
    asn         = var.my-azure-bgp-asn
    peer_weight = 100

    peering_addresses {
      ip_configuration_name = "vnetGatewayConfig1"
      apipa_addresses       = ["169.254.21.1"]
    }

    peering_addresses {
      ip_configuration_name = "vnetGatewayConfig2"
      apipa_addresses       = ["169.254.22.1"]
    }

  }

}

resource "azurerm_local_network_gateway" "my-azure-local-gateway-1" {
  name                = "gcp-local-network-gateway-1"
  location            = var.my-azure-region
  resource_group_name = azurerm_resource_group.my-azure-resource-group.name

  gateway_address = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.vpn_interfaces[0].ip_address

  bgp_settings {
    asn                 = var.my-gcp-bgp-asn
    bgp_peering_address = google_compute_router_peer.my-gcp-router-peer-1.ip_address
  }
}

resource "azurerm_local_network_gateway" "my-azure-local-gateway-2" {
  name                = "gcp-local-network-gateway-2"
  location            = var.my-azure-region
  resource_group_name = azurerm_resource_group.my-azure-resource-group.name

  gateway_address = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.vpn_interfaces[1].ip_address

  bgp_settings {
    asn                 = var.my-gcp-bgp-asn
    bgp_peering_address = google_compute_router_peer.my-gcp-router-peer-2.ip_address
  }
}

resource "azurerm_virtual_network_gateway_connection" "my-azure-cx-1" {
  name                = "azure-to-gcp-vpn-connection-1"
  location            = var.my-azure-region
  resource_group_name = azurerm_resource_group.my-azure-resource-group.name

  type = "IPsec"

  virtual_network_gateway_id = azurerm_virtual_network_gateway.my-azure-vpn-gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.my-azure-local-gateway-1.id
  shared_key                 = var.my-shared-secret

  enable_bgp = true
}

resource "azurerm_virtual_network_gateway_connection" "my-azure-cx-2" {
  name                = "azure-to-gcp-vpn-connection-2"
  location            = var.my-azure-region
  resource_group_name = azurerm_resource_group.my-azure-resource-group.name

  type = "IPsec"

  virtual_network_gateway_id = azurerm_virtual_network_gateway.my-azure-vpn-gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.my-azure-local-gateway-2.id
  shared_key                 = var.my-shared-secret

  enable_bgp = true
}
