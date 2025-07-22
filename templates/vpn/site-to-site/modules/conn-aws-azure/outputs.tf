output "aws_vpn_conn_info" {
  description = "AWS, VPN connection resource details"
  value = {
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
}

output "azure_vpn_conn_info" {
  description = "Azure, VPN connection resources details"
  value = {
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
    bgp_asn = var.azure_bgp_asn
  }
}
