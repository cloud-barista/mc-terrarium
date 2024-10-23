
output "gcp_router_id" {
  value = google_compute_router.router_1.id
}

output "gcp_ha_vpn_gateway_id" {
  value = google_compute_ha_vpn_gateway.ha_vpn_gw_1.id
}

output "gcp_external_vpn_gateway_id" {
  value = google_compute_external_vpn_gateway.external_vpn_gw_1.id
}

output "gcp_vpn_tunnel_1_id" {
  value = google_compute_vpn_tunnel.vpn_tunnel_1.id
}

output "gcp_vpn_tunnel_2_id" {
  value = google_compute_vpn_tunnel.vpn_tunnel_2.id
}

output "gcp_router_interface_1_id" {
  value = google_compute_router_interface.router_interface_1.id
}

output "gcp_router_interface_2_id" {
  value = google_compute_router_interface.router_interface_2.id
}

output "gcp_router_peer_1_id" {
  value = google_compute_router_peer.router_peer_1.id
}

output "gcp_router_peer_2_id" {
  value = google_compute_router_peer.router_peer_2.id
}

# output "injected_vpc_network_id" {
#   value = data.google_compute_network.injected_vpc_network.id
# }

# output "injected_vpc_network_self_link" {
#   value = data.google_compute_network.injected_vpc_network.self_link
# }

output "azure_gw_subnet_id" {
  value = azurerm_subnet.gw_subnet.id
}

output "azure_vpn_gw_pub_ip_1" {
  value = azurerm_public_ip.vpn_gw_pub_ip_1.ip_address
}

output "azure_vpn_gw_pub_ip_2" {
  value = azurerm_public_ip.vpn_gw_pub_ip_2.ip_address
}

output "azure_vpn_gw_id" {
  value = azurerm_virtual_network_gateway.vpn_gw_1.id
}

output "azurerm_local_network_gateway_peer_gw_1_id" {
  value = azurerm_local_network_gateway.peer_gw_1.id
}
output "azurerm_local_network_gateway_peer_gw_2_id" {
  value = azurerm_local_network_gateway.peer_gw_2.id
}

output "azurerm_virtual_network_gateway_connection_1_id" {
  value = azurerm_virtual_network_gateway_connection.gcp_and_azure_cnx_1.id
}

output "azurerm_virtual_network_gateway_connection_2_id" {
  value = azurerm_virtual_network_gateway_connection.gcp_and_azure_cnx_2.id
}
