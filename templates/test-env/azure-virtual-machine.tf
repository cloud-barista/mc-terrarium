resource "azurerm_network_interface" "test_nic_1" {
  name                = "tr-nic-1-name"
  location            = azurerm_resource_group.test_rg.location
  resource_group_name = azurerm_resource_group.test_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test_subnet_1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Make an association between the network interface and the security group
resource "azurerm_network_interface_security_group_association" "test_nic_nsg_association_1" {
  network_interface_id      = azurerm_network_interface.test_nic_1.id
  network_security_group_id = azurerm_network_security_group.test_nsg_1.id
}

# Create a virtual machine
resource "azurerm_linux_virtual_machine" "test_vm_1" {
  name                = "tr-vm-1-name"
  resource_group_name = azurerm_resource_group.test_rg.name
  location            = azurerm_resource_group.test_rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser" # Ensure this matches Azure's expected default path
  network_interface_ids = [
    azurerm_network_interface.test_nic_1.id,
  ]

  # Read SSH key from a file
  # admin_ssh_key {
  #   username   = "adminuser"
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  # Generate SSH key
  admin_ssh_key {
    username   = "adminuser" # This should match the admin_username
    public_key = azapi_resource_action.test_azure_ssh_public_key_gen.output.publicKey
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
