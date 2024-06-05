# Define a resource group
resource "azurerm_resource_group" "test_rg" {
  name     = var.azure-resource-group-name
  location = var.azure-region # Default: "koreacentral"
}

# Define a virtual network
resource "azurerm_virtual_network" "test_vnet" {
  name                = "tr-azure-vnet"
  address_space       = ["192.168.128.0/18"]
  location            = azurerm_resource_group.test_rg.location
  resource_group_name = azurerm_resource_group.test_rg.name
}

# Define subnets
resource "azurerm_subnet" "test_subnet_0" {
  name                 = "tr-azure-subnet-0"
  resource_group_name  = azurerm_resource_group.test_rg.name
  virtual_network_name = azurerm_virtual_network.test_vnet.name
  address_prefixes     = ["192.168.128.0/24"]
}


resource "azurerm_subnet" "test_subnet_1" {
  name                 = "tr-azure-subnet-1"
  resource_group_name  = azurerm_resource_group.test_rg.name
  virtual_network_name = azurerm_virtual_network.test_vnet.name
  address_prefixes     = ["192.168.129.0/24"]
}