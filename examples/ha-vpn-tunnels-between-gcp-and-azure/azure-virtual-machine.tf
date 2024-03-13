resource "azurerm_network_interface" "my-azure-network-interface" {
  name                = "my-azure-nic-name"
  location            = azurerm_resource_group.my-azure-resource-group.location
  resource_group_name = azurerm_resource_group.my-azure-resource-group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.my-azure-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Make an association between the network interface and the security group
resource "azurerm_network_interface_security_group_association" "my-azure-nic-nsg-association" {
  network_interface_id      = azurerm_network_interface.my-azure-network-interface.id
  network_security_group_id = azurerm_network_security_group.my-azure-network-security-group.id
}

# Create a virtual machine
resource "azurerm_linux_virtual_machine" "my-azure-vm" {
  name                = "my-azure-vm-name"
  resource_group_name = azurerm_resource_group.my-azure-resource-group.name
  location            = azurerm_resource_group.my-azure-resource-group.location
  size                = "Standard_F2"
  admin_username      = "adminuser" # Ensure this matches Azure's expected default path
  network_interface_ids = [
    azurerm_network_interface.my-azure-network-interface.id,
  ]

  # Read SSH key from a file
  # admin_ssh_key {
  #   username   = "adminuser"
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  # Generate SSH key
  admin_ssh_key {
    username   = "adminuser" # This should match the admin_username
    public_key = jsondecode(azapi_resource_action.my-azure-ssh-public-key-gen.output).publicKey
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

# # Generate random text for a unique storage account name
# resource "random_id" "random_id" {
#   keepers = {
#     # Generate a new ID only when a new resource group is defined
#     resource_group = azurerm_resource_group.my-azure-resource-group.name
#   }

#   byte_length = 8
# }

# # Create storage account for boot diagnostics
# resource "azurerm_storage_account" "my_storage_account" {
#   name                     = "diag${random_id.random_id.hex}"
#   location                 = azurerm_resource_group.my-azure-resource-group.location
#   resource_group_name      = azurerm_resource_group.my-azure-resource-group.name
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
# }

# # Create virtual machine
# resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
#   name                  = "myVM"
#   location              = azurerm_resource_group.my-azure-resource-group.location
#   resource_group_name   = azurerm_resource_group.my-azure-resource-group.name
#   network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
#   size                  = "Standard_DS1_v2"

#   os_disk {
#     name                 = "myOsDisk"
#     caching              = "ReadWrite"
#     storage_account_type = "Premium_LRS"
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts-gen2"
#     version   = "latest"
#   }

#   computer_name  = "hostname"
#   admin_username = var.username

#   admin_ssh_key {
#     username   = var.username
#     public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
#   }

#   boot_diagnostics {
#     storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
#   }
# }
