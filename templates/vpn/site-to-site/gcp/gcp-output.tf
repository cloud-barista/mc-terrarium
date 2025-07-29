# Output GCP VPN Gateway information
output "gcp_vpn_gateway_info" {
  description = "GCP HA VPN Gateway details"
  value = {
    id        = google_compute_ha_vpn_gateway.vpn_gw.id
    name      = google_compute_ha_vpn_gateway.vpn_gw.name
    self_link = google_compute_ha_vpn_gateway.vpn_gw.self_link
    vpn_interfaces = [
      for i, interface in google_compute_ha_vpn_gateway.vpn_gw.vpn_interfaces : {
        id         = interface.id
        ip_address = interface.ip_address
      }
    ]
  }
}

output "gcp_router_info" {
  description = "GCP Cloud Router details"
  value = {
    id        = google_compute_router.vpn_router.id
    name      = google_compute_router.vpn_router.name
    self_link = google_compute_router.vpn_router.self_link
    bgp_asn   = google_compute_router.vpn_router.bgp[0].asn
  }
}
