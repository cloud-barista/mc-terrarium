output "vpn_info" {
  description = "VPN connection information"
  value = {
    aws = {
      customer_gateways = [
        for i, cgw in aws_customer_gateway.azure_gw : {
          resource_type = "aws_customer_gateway"
          name          = try(cgw.tags.Name, "")
          id            = try(cgw.id, "")
          ip_address    = try(cgw.ip_address, "")
          bgp_asn       = try(cgw.bgp_asn, "")
        }
      ]
      vpn_connections = [
        for i, vpn in aws_vpn_connection.to_azure : {
          resource_type   = "aws_vpn_connection"
          name            = try(vpn.tags.Name, "")
          id              = try(vpn.id, "")
          tunnel1_address = try(vpn.tunnel1_address, "")
          tunnel2_address = try(vpn.tunnel2_address, "")
        }
      ]
    }
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
      connections = [
        for conn in azurerm_virtual_network_gateway_connection.to_aws : {
          resource_type = "azurerm_virtual_network_gateway_connection"
          name          = try(conn.name, "")
          id            = try(conn.id, "")
          type          = try(conn.type, "")
          enable_bgp    = try(conn.enable_bgp, "")
        }
      ]
      local_gateways = [
        for lgw in azurerm_local_network_gateway.aws_gw : {
          resource_type   = "azurerm_local_network_gateway"
          name            = try(lgw.name, "")
          id              = try(lgw.id, "")
          gateway_address = try(lgw.gateway_address, "")
        }
      ]
      bgp_asn = var.bgp_asn
    }
  }
}
