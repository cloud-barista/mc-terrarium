output "azure_vpn_conn_info" {
  description = "Azure, VPN connection resources details"
  value = {
    connections = [
      for conn in azurerm_virtual_network_gateway_connection.to_gcp : {
        resource_type = "azurerm_virtual_network_gateway_connection"
        name          = try(conn.name, "")
        id            = try(conn.id, "")
        type          = try(conn.type, "")
        enable_bgp    = try(conn.enable_bgp, "")
      }
    ]
    local_gateways = [
      for lgw in azurerm_local_network_gateway.gcp_gw : {
        resource_type   = "azurerm_local_network_gateway"
        name            = try(lgw.name, "")
        id              = try(lgw.id, "")
        gateway_address = try(lgw.gateway_address, "")
      }
    ]
    bgp_asn = var.azure_bgp_asn
  }
}

output "gcp_vpn_conn_info" {
  description = "GCP, VPN connection resources details"
  value = {
    external_vpn_gateway = {
      resource_type   = "google_compute_external_vpn_gateway"
      name            = try(google_compute_external_vpn_gateway.azure_peer_gw.name, "")
      id              = try(google_compute_external_vpn_gateway.azure_peer_gw.id, "")
      redundancy_type = try(google_compute_external_vpn_gateway.azure_peer_gw.redundancy_type, "")
    }
    vpn_tunnels = [
      for tunnel in google_compute_vpn_tunnel.to_azure : {
        resource_type = "google_compute_vpn_tunnel"
        name          = try(tunnel.name, "")
        id            = try(tunnel.id, "")
        status        = try(tunnel.status, "")
      }
    ]
    router_interfaces = [
      for interface in google_compute_router_interface.tunnel_interfaces : {
        resource_type = "google_compute_router_interface"
        name          = try(interface.name, "")
        ip_range      = try(interface.ip_range, "")
      }
    ]
    router_peers = [
      for peer in google_compute_router_peer.azure_peers : {
        resource_type   = "google_compute_router_peer"
        name            = try(peer.name, "")
        peer_ip_address = try(peer.peer_ip_address, "")
        peer_asn        = try(peer.peer_asn, "")
      }
    ]
    bgp_asn = var.gcp_bgp_asn
  }
}
