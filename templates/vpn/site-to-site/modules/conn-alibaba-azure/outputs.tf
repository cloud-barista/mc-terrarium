output "alibaba_vpn_conn_info" {
  description = "Alibaba, VPN connection resource details"
  value = {
    resource_type = "VPN Connection"
    customer_gateways = [
      for i, cgw in alicloud_vpn_customer_gateway.azure_gw : {
        resource_type = "alicloud_vpn_customer_gateway"
        name          = try(cgw.customer_gateway_name, "")
        id            = try(cgw.id, "")
        ip_address    = try(cgw.ip_address, "")
        description   = try(cgw.description, "")
      }
    ]
    vpn_connections = [
      for i, vpn in alicloud_vpn_connection.to_azure : {
        resource_type = "alicloud_vpn_connection"
        name          = try(vpn.vpn_connection_name, "")
        id            = try(vpn.id, "")
        local_subnet  = try(vpn.local_subnet, [])
        remote_subnet = try(vpn.remote_subnet, [])
        status        = try(vpn.status, "")
      }
    ]
    bgp_asn = var.alibaba_bgp_asn
  }
}

output "azure_vpn_conn_info" {
  description = "Azure, VPN connection resource details"
  value = {
    resource_type = "VPN Connection"
    connections = [
      for conn in azurerm_virtual_network_gateway_connection.to_alibaba : {
        resource_type = "azurerm_virtual_network_gateway_connection"
        name          = try(conn.name, "")
        id            = try(conn.id, "")
        type          = try(conn.type, "")
        enable_bgp    = try(conn.enable_bgp, "")
      }
    ]
    local_gateways = [
      for lgw in azurerm_local_network_gateway.alibaba_gw : {
        resource_type       = "azurerm_local_network_gateway"
        name                = try(lgw.name, "")
        id                  = try(lgw.id, "")
        gateway_address     = try(lgw.gateway_address, "")
        bgp_peering_address = try(lgw.bgp_settings[0].bgp_peering_address, "")
      }
    ]
    bgp_asn = var.azure_bgp_asn
  }
}
