output "vpn_info" {
  description = "VPN connection information"
  value = {
    aws = {
      customer_gateways = [
        for i, cgw in aws_customer_gateway.gcp_gw : {
          resource_type = "aws_customer_gateway"
          name          = try(cgw.tags.Name, "")
          id            = try(cgw.id, "")
          ip_address    = try(cgw.ip_address, "")
          bgp_asn       = try(cgw.bgp_asn, "")
        }
      ]
      vpn_connections = [
        for i, vpn in aws_vpn_connection.to_gcp : {
          resource_type   = "aws_vpn_connection"
          name            = try(vpn.tags.Name, "")
          id              = try(vpn.id, "")
          tunnel1_address = try(vpn.tunnel1_address, "")
          tunnel2_address = try(vpn.tunnel2_address, "")
        }
      ]
    }
    gcp = {
      vpn_gateway = {
        resource_type = "google_compute_ha_vpn_gateway"
        name          = try(google_compute_ha_vpn_gateway.vpn_gw.name, "")
        id            = try(google_compute_ha_vpn_gateway.vpn_gw.id, "")
        network       = try(google_compute_ha_vpn_gateway.vpn_gw.network, "")
        region        = try(google_compute_ha_vpn_gateway.vpn_gw.region, "")
      }
      external_gateway = {
        resource_type   = "google_compute_external_vpn_gateway"
        name            = try(google_compute_external_vpn_gateway.aws_gw.name, "")
        id              = try(google_compute_external_vpn_gateway.aws_gw.id, "")
        redundancy_type = try(google_compute_external_vpn_gateway.aws_gw.redundancy_type, "")
        description     = try(google_compute_external_vpn_gateway.aws_gw.description, "")
        interfaces = [
          for iface in google_compute_external_vpn_gateway.aws_gw.interface : {
            id         = try(iface.id, "")
            ip_address = try(iface.ip_address, "")
          }
        ]
      }
      router = {
        resource_type = "google_compute_router"
        name          = try(google_compute_router.router.name, "")
        id            = try(google_compute_router.router.id, "")
        network       = try(google_compute_router.router.network, "")
        bgp_asn       = try(var.bgp_asn, "")
      }
      tunnels = [
        for tunnel in google_compute_vpn_tunnel.to_aws : {
          resource_type = "google_compute_vpn_tunnel"
          name          = try(tunnel.name, "")
          id            = try(tunnel.id, "")
          peer_ip       = try(tunnel.peer_ip, "")
          interface     = try(tunnel.vpn_gateway_interface, "")
        }
      ]
      interfaces = [
        for iface in google_compute_router_interface.router_interface : {
          resource_type = "google_compute_router_interface"
          name          = try(iface.name, "")
          id            = try(iface.id, "")
          ip_range      = try(iface.ip_range, "")
        }
      ]
      peers = [
        for peer in google_compute_router_peer.router_peer : {
          resource_type = "google_compute_router_peer"
          name          = try(peer.name, "")
          id            = try(peer.id, "")
          peer_ip       = try(peer.peer_ip_address, "")
          peer_asn      = try(peer.peer_asn, "")
        }
      ]
    }
  }
}
