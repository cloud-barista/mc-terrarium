
output "azure_vpn_info" {
  description = "Azure, VPN resource details"
  value = merge(
    // Azure VPN Gateway details
    {
      azure = {
        vpn_gateway = {
          resource_type = "azurerm_virtual_network_gateway"
          name          = try(azurerm_virtual_network_gateway.vpn_gw.name, "")
          id            = try(azurerm_virtual_network_gateway.vpn_gw.id, "")
          location      = try(azurerm_virtual_network_gateway.vpn_gw.location, "")
          sku           = try(azurerm_virtual_network_gateway.vpn_gw.sku, "")
        }
        public_ips = [
          for pip in azurerm_public_ip.pub_ip : {
            resource_type = "azurerm_public_ip"
            name          = try(pip.name, "")
            id            = try(pip.id, "")
            ip_address    = try(pip.ip_address, "")
          }
        ]
      }
    },
    // Azure VPN connection details
    try(module.conn_aws_azure.azure_vpn_conn_info, {})
    // To be added, Azure VPN connection details with other providers
    // e.g., Alibaba, GCP, etc.
  )
}
