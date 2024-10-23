
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

output "gcp_vpn_tunnel_3_id" {
  value = google_compute_vpn_tunnel.vpn_tunnel_3.id
}

output "gcp_vpn_tunnel_4_id" {
  value = google_compute_vpn_tunnel.vpn_tunnel_4.id
}

output "gcp_router_interface_1_id" {
  value = google_compute_router_interface.router_interface_1.id
}

output "gcp_router_interface_2_id" {
  value = google_compute_router_interface.router_interface_2.id
}

output "gcp_router_interface_3_id" {
  value = google_compute_router_interface.router_interface_3.id
}

output "gcp_router_interface_4_id" {
  value = google_compute_router_interface.router_interface_4.id
}

output "gcp_router_peer_1_id" {
  value = google_compute_router_peer.router_peer_1.id
}

output "gcp_router_peer_2_id" {
  value = google_compute_router_peer.router_peer_2.id
}

output "gcp_router_peer_3_id" {
  value = google_compute_router_peer.router_peer_3.id
}

output "gcp_router_peer_4_id" {
  value = google_compute_router_peer.router_peer_4.id
}

# output "injected_vpc_network_id" {
#   value = data.google_compute_network.injected_vpc_network.id
# }

# output "injected_vpc_network_self_link" {
#   value = data.google_compute_network.injected_vpc_network.self_link
# }

output "aws_vpn_gw_id" {
  value = aws_vpn_gateway.vpn_gw.id
}

output "aws_customer_gateway_id_1" {
  value = aws_customer_gateway.cgw_1.id
}

output "aws_customer_gateway_id_2" {
  value = aws_customer_gateway.cgw_2.id
}

output "aws_vpn_connection_id_1" {
  value = aws_vpn_connection.vpn_cnx_1.id
}

output "aws_vpn_connection_id_2" {
  value = aws_vpn_connection.vpn_cnx_2.id
}
