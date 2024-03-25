# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg_1" {
  name                = "nsg-1-name"
  location            = var.azure-region
  resource_group_name = var.azure-resource-group-name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                        = "ICMP"
    priority                    = 3000
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Icmp"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}
