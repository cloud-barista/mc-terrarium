variable "azure-region" {
  type        = string
  description = "A location (region) in MS Azure."
  default     = "koreacentral"
  # Azure regions mapping list:
  # https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md  
}

variable "azure-resource-group-name" {
  type        = string
  default     = "tofu-rg-01"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

resource "azurerm_resource_group" "test_rg" {
  name     = var.azure-resource-group-name
  # Default: "koreacentral"
  location = var.azure-region
}

# Create a virtual network
resource "azurerm_virtual_network" "test_vnet" {
  name                = "tofu-azure-vnet"
  address_space       = ["192.168.128.0/18"]
  location            = azurerm_resource_group.test_rg.location
  resource_group_name = azurerm_resource_group.test_rg.name
}

# Create subnets
resource "azurerm_subnet" "test_subnet" {
  name                 = "tofu-azure-subnet-0"
  resource_group_name  = azurerm_resource_group.test_rg.name
  virtual_network_name = azurerm_virtual_network.test_vnet.name
  address_prefixes     = ["192.168.128.0/24"]
}


resource "azurerm_subnet" "test_gw_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.test_rg.name
  virtual_network_name = azurerm_virtual_network.test_vnet.name
  address_prefixes     = ["192.168.129.0/24"]
}