# outputs.tf
output "testbed_info" {
  value = {
    region               = azurerm_resource_group.main.location
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    gateway_subnet_cidr  = "10.2.2.0/24" # Reserved for VPN Gateway
    private_ip           = azurerm_network_interface.main.private_ip_address
  }
}

data "azurerm_public_ip" "main" {
  name                = azurerm_public_ip.main.name
  resource_group_name = azurerm_resource_group.main.name
  depends_on          = [azurerm_linux_virtual_machine.main]
}

output "ssh_info" {
  sensitive = true
  value = {
    public_ip  = data.azurerm_public_ip.main.ip_address
    private_ip = azurerm_network_interface.main.private_ip_address
    user       = "ubuntu"
    command    = "ssh -i private_key.pem ubuntu@${data.azurerm_public_ip.main.ip_address}"
  }

  depends_on = [azurerm_linux_virtual_machine.main, data.azurerm_public_ip.main]
}
