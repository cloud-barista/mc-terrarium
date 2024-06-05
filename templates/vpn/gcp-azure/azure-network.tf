# Azure existing virtual network and subnet
data "azurerm_virtual_network" "injected_vnet" {
  name                = var.azure-virtual-network-name
  resource_group_name = var.azure-resource-group-name
}

resource "azurerm_subnet" "gw_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.azure-resource-group-name
  virtual_network_name = data.azurerm_virtual_network.injected_vnet.name
  address_prefixes     = [var.azure-gateway-subnet-cidr-block]
}

# Create public IP addresses
resource "azurerm_public_ip" "vpn_gw_pub_ip_1" {
  name                = "${var.terrarium-id}-vpn-gw-pub-ip-1"
  location            = var.azure-region
  resource_group_name = var.azure-resource-group-name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = contains(var.azure_vpn_allowed_az_skus, var.azure_vpn_sku) ? ["1", "2", "3"] : []
}

resource "azurerm_public_ip" "vpn_gw_pub_ip_2" {
  name                = "${var.terrarium-id}-vpn-gw-pub-ip-2"
  location            = var.azure-region
  resource_group_name = var.azure-resource-group-name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = contains(var.azure_vpn_allowed_az_skus, var.azure_vpn_sku) ? ["1", "2", "3"] : []
}

# Create Azure VPN Gateway and connections
resource "azurerm_virtual_network_gateway" "vpn_gw_1" {
  name                = "${var.terrarium-id}-vpn-gw-1"
  location            = var.azure-region
  resource_group_name = var.azure-resource-group-name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = var.azure_vpn_sku

  ip_configuration {
    name                          = "${var.terrarium-id}-vnetGatewayConfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gw_subnet.id
    public_ip_address_id          = azurerm_public_ip.vpn_gw_pub_ip_1.id
  }

  ip_configuration {
    name                          = "${var.terrarium-id}-vnetGatewayConfig2"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gw_subnet.id
    public_ip_address_id          = azurerm_public_ip.vpn_gw_pub_ip_2.id
  }

  bgp_settings {
    asn         = var.azure-bgp-asn
    peer_weight = 100

    peering_addresses {
      ip_configuration_name = "${var.terrarium-id}-vnetGatewayConfig1"
      apipa_addresses       = ["169.254.21.1"]
    }

    peering_addresses {
      ip_configuration_name = "${var.terrarium-id}-vnetGatewayConfig2"
      apipa_addresses       = ["169.254.22.1"]
    }

  }

}

########################################################
# From here, GCP's resources are required.
########################################################

resource "azurerm_local_network_gateway" "peer_gw_1" {
  name                = "${var.terrarium-id}-gcp-side-gateway-1"
  location            = var.azure-region
  resource_group_name = var.azure-resource-group-name

  gateway_address = google_compute_ha_vpn_gateway.ha_vpn_gw_1.vpn_interfaces[0].ip_address

  bgp_settings {
    asn                 = var.gcp-bgp-asn
    bgp_peering_address = google_compute_router_peer.router_peer_1.ip_address
  }
}

resource "azurerm_local_network_gateway" "peer_gw_2" {
  name                = "${var.terrarium-id}-gcp-side-gateway-2"
  location            = var.azure-region
  resource_group_name = var.azure-resource-group-name

  gateway_address = google_compute_ha_vpn_gateway.ha_vpn_gw_1.vpn_interfaces[1].ip_address

  bgp_settings {
    asn                 = var.gcp-bgp-asn 
    bgp_peering_address = google_compute_router_peer.router_peer_2.ip_address
  }
}

resource "azurerm_virtual_network_gateway_connection" "gcp_and_azure_cnx_1" {
  name                = "${var.terrarium-id}-connection-1"
  location            = var.azure-region
  resource_group_name = var.azure-resource-group-name

  type = "IPsec"

  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw_1.id
  local_network_gateway_id   = azurerm_local_network_gateway.peer_gw_1.id
  shared_key                 = var.preshared-secret

  enable_bgp = true
}

resource "azurerm_virtual_network_gateway_connection" "gcp_and_azure_cnx_2" {
  name                = "${var.terrarium-id}-connection-2"
  location            = var.azure-region
  resource_group_name = var.azure-resource-group-name

  type = "IPsec"

  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw_1.id
  local_network_gateway_id   = azurerm_local_network_gateway.peer_gw_2.id
  shared_key                 = var.preshared-secret

  enable_bgp = true
}
