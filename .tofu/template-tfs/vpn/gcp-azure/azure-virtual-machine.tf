
data "azurerm_subnet" "injected_subnet" {
  name                 = var.azure-subnet-name
  virtual_network_name = data.azurerm_virtual_network.injected_vnet.name
  resource_group_name  = var.azure-resource-group-name
}

resource "azurerm_network_interface" "nic_1" {
  name                = "nic-1-name"
  location            = var.azure-region
  resource_group_name = var.azure-resource-group-name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.injected_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Make an association between the network interface and the security group
resource "azurerm_network_interface_security_group_association" "nic_nsg_association_1" {
  network_interface_id      = azurerm_network_interface.nic_1.id
  network_security_group_id = azurerm_network_security_group.nsg_1.id
}

# Create a virtual machine
resource "azurerm_linux_virtual_machine" "vm_1" {
  name                = "vm-1-name"
  resource_group_name = var.azure-resource-group-name
  location            = var.azure-region
  size                = "Standard_F2"
  admin_username      = "adminuser" # Ensure this matches Azure's expected default path
  network_interface_ids = [
    azurerm_network_interface.nic_1.id,
  ]

  # Read SSH key from a file
  # admin_ssh_key {
  #   username   = "adminuser"
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  # Generate SSH key
  admin_ssh_key {
    username   = "adminuser" # This should match the admin_username
    public_key = jsondecode(azapi_resource_action.azure_ssh_public_key_gen.output).publicKey
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
