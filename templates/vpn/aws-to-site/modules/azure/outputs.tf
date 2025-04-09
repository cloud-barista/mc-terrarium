output "vpn_info" {
  description = "VPN connection information"
  value = {
    aws = {
      customer_gateways = try([
        for i, cgw in aws_customer_gateway.azure_gw : {
          resource_type = "aws_customer_gateway"
          name          = cgw.tags.Name
          id            = cgw.id
          ip_address    = cgw.ip_address
          bgp_asn       = cgw.bgp_asn
        }
      ], [])
      vpn_connections = try([
        for i, vpn in aws_vpn_connection.to_azure : {
          resource_type   = "aws_vpn_connection"
          name            = vpn.tags.Name
          id              = vpn.id
          tunnel1_address = vpn.tunnel1_address
          tunnel2_address = vpn.tunnel2_address
        }
      ], [])
    }
    azure = {
      vpn_gateway = try({
        resource_type = "azurerm_virtual_network_gateway"
        name          = azurerm_virtual_network_gateway.vpn_gw.name
        id            = azurerm_virtual_network_gateway.vpn_gw.id
        location      = azurerm_virtual_network_gateway.vpn_gw.location
        sku           = azurerm_virtual_network_gateway.vpn_gw.sku
      }, null)
      public_ips = try([
        for pip in azurerm_public_ip.pub_ip : {
          resource_type = "azurerm_public_ip"
          name          = pip.name
          id            = pip.id
          ip_address    = pip.ip_address
        }
      ], [])
      connections = try([
        for conn in azurerm_virtual_network_gateway_connection.to_aws : {
          resource_type = "azurerm_virtual_network_gateway_connection"
          name          = conn.name
          id            = conn.id
          type          = conn.type
          enable_bgp    = conn.enable_bgp
        }
      ], [])
      local_gateways = try([
        for lgw in azurerm_local_network_gateway.aws_gw : {
          resource_type   = "azurerm_local_network_gateway"
          name            = lgw.name
          id              = lgw.id
          gateway_address = lgw.gateway_address
        }
      ], [])
      bgp_asn = var.bgp_asn
    }
  }
}
