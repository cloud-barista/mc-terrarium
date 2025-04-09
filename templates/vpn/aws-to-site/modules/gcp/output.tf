output "vpn_info" {
  description = "VPN connection information"
  value = {
    aws = {
      customer_gateways = try([
        for i, cgw in aws_customer_gateway.gcp_gw : {
          resource_type = "aws_customer_gateway"
          name          = cgw.tags.Name
          id            = cgw.id
          ip_address    = cgw.ip_address
          bgp_asn       = cgw.bgp_asn
        }
      ], [])
      vpn_connections = try([
        for i, vpn in aws_vpn_connection.to_gcp : {
          resource_type   = "aws_vpn_connection"
          name            = vpn.tags.Name
          id              = vpn.id
          tunnel1_address = vpn.tunnel1_address
          tunnel2_address = vpn.tunnel2_address
        }
      ], [])
    }
    gcp = {
      vpn_gateway = try({
        resource_type = "google_compute_ha_vpn_gateway"
        name          = google_compute_ha_vpn_gateway.vpn_gw.name
        id            = google_compute_ha_vpn_gateway.vpn_gw.id
        network       = google_compute_ha_vpn_gateway.vpn_gw.network
        region        = google_compute_ha_vpn_gateway.vpn_gw.region
      }, {})
      external_gateway = try({
        resource_type   = "google_compute_external_vpn_gateway"
        name            = google_compute_external_vpn_gateway.aws_gw.name
        id              = google_compute_external_vpn_gateway.aws_gw.id
        redundancy_type = google_compute_external_vpn_gateway.aws_gw.redundancy_type
        description     = google_compute_external_vpn_gateway.aws_gw.description
        interfaces = [
          for iface in google_compute_external_vpn_gateway.aws_gw.interface : {
            id         = iface.id
            ip_address = iface.ip_address
          }
        ]
      }, {})
      router = try({
        resource_type = "google_compute_router"
        name          = google_compute_router.router.name
        id            = google_compute_router.router.id
        network       = google_compute_router.router.network
        bgp_asn       = var.bgp_asn
      }, {})
      tunnels = try([
        for tunnel in google_compute_vpn_tunnel.to_aws : {
          resource_type = "google_compute_vpn_tunnel"
          name          = tunnel.name
          id            = tunnel.id
          peer_ip       = tunnel.peer_ip
          interface     = tunnel.vpn_gateway_interface
        }
      ], [])
      interfaces = try([
        for iface in google_compute_router_interface.router_interface : {
          resource_type = "google_compute_router_interface"
          name          = iface.name
          id            = iface.id
          ip_range      = iface.ip_range
        }
      ], [])
      peers = try([
        for peer in google_compute_router_peer.router_peer : {
          resource_type = "google_compute_router_peer"
          name          = peer.name
          id            = peer.id
          peer_ip       = peer.peer_ip_address
          peer_asn      = peer.peer_asn
        }
      ], [])
    }
  }
}
