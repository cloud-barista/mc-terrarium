
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

output "vpn_info" {
  description = "VPN connection information for both AWS and GCP"
  value = {
    terrarium = {
      id = var.terrarium-id
    }
    aws = {
      vpn_gateway = {
        resource_type = "aws_vpn_gateway"
        name         = aws_vpn_gateway.vpn_gw.tags.Name
        id           = aws_vpn_gateway.vpn_gw.id
        vpc_id       = aws_vpn_gateway.vpn_gw.vpc_id
      }
      customer_gateways = [
        {
          resource_type = "aws_customer_gateway"
          name         = aws_customer_gateway.cgw_1.tags.Name
          id           = aws_customer_gateway.cgw_1.id
          ip_address   = aws_customer_gateway.cgw_1.ip_address
          bgp_asn      = aws_customer_gateway.cgw_1.bgp_asn
        },
        {
          resource_type = "aws_customer_gateway"
          name         = aws_customer_gateway.cgw_2.tags.Name
          id           = aws_customer_gateway.cgw_2.id
          ip_address   = aws_customer_gateway.cgw_2.ip_address
          bgp_asn      = aws_customer_gateway.cgw_2.bgp_asn
        }
      ]
      vpn_connections = [
        {
          resource_type = "aws_vpn_connection"
          name         = aws_vpn_connection.vpn_cnx_1.tags.Name
          id           = aws_vpn_connection.vpn_cnx_1.id
          tunnel1_address = aws_vpn_connection.vpn_cnx_1.tunnel1_address
          tunnel2_address = aws_vpn_connection.vpn_cnx_1.tunnel2_address
        },
        {
          resource_type = "aws_vpn_connection"
          name         = aws_vpn_connection.vpn_cnx_2.tags.Name
          id           = aws_vpn_connection.vpn_cnx_2.id
          tunnel1_address = aws_vpn_connection.vpn_cnx_2.tunnel1_address
          tunnel2_address = aws_vpn_connection.vpn_cnx_2.tunnel2_address
        }
      ]
    }
    gcp = {
      router = {
        resource_type = "google_compute_router"
        name         = google_compute_router.router_1.name
        id           = google_compute_router.router_1.id
        network      = google_compute_router.router_1.network
        bgp_asn      = google_compute_router.router_1.bgp[0].asn
      }
      ha_vpn_gateway = {
        resource_type = "google_compute_ha_vpn_gateway"
        name         = google_compute_ha_vpn_gateway.ha_vpn_gw_1.name
        id           = google_compute_ha_vpn_gateway.ha_vpn_gw_1.id
        network      = google_compute_ha_vpn_gateway.ha_vpn_gw_1.network
        ip_addresses = google_compute_ha_vpn_gateway.ha_vpn_gw_1.vpn_interfaces[*].ip_address
      }
      vpn_tunnels = [
        {
          resource_type = "google_compute_vpn_tunnel"
          name         = google_compute_vpn_tunnel.vpn_tunnel_1.name
          id           = google_compute_vpn_tunnel.vpn_tunnel_1.id
          ike_version  = google_compute_vpn_tunnel.vpn_tunnel_1.ike_version
          interface    = google_compute_vpn_tunnel.vpn_tunnel_1.vpn_gateway_interface
        },
        {
          resource_type = "google_compute_vpn_tunnel"
          name         = google_compute_vpn_tunnel.vpn_tunnel_2.name
          id           = google_compute_vpn_tunnel.vpn_tunnel_2.id
          ike_version  = google_compute_vpn_tunnel.vpn_tunnel_2.ike_version
          interface    = google_compute_vpn_tunnel.vpn_tunnel_2.vpn_gateway_interface
        },
        {
          resource_type = "google_compute_vpn_tunnel"
          name         = google_compute_vpn_tunnel.vpn_tunnel_3.name
          id           = google_compute_vpn_tunnel.vpn_tunnel_3.id
          ike_version  = google_compute_vpn_tunnel.vpn_tunnel_3.ike_version
          interface    = google_compute_vpn_tunnel.vpn_tunnel_3.vpn_gateway_interface
        },
        {
          resource_type = "google_compute_vpn_tunnel"
          name         = google_compute_vpn_tunnel.vpn_tunnel_4.name
          id           = google_compute_vpn_tunnel.vpn_tunnel_4.id
          ike_version  = google_compute_vpn_tunnel.vpn_tunnel_4.ike_version
          interface    = google_compute_vpn_tunnel.vpn_tunnel_4.vpn_gateway_interface
        }
      ]
    }
  }
}