output "vpn_info" {
  description = "VPN connection information"
  value = {
    terrarium = {
      id = var.vpn_config.terrarium_id
    }
    aws = {
      vpn_gateway = {
        resource_type = "aws_vpn_gateway"
        name          = aws_vpn_gateway.vpn_gw.tags.Name
        id            = aws_vpn_gateway.vpn_gw.id
        vpc_id        = aws_vpn_gateway.vpn_gw.vpc_id
      }
      customer_gateways = (
        local.is_gcp ? [
          for i, cgw in aws_customer_gateway.gcp_gw : {
            resource_type = "aws_customer_gateway"
            name          = cgw.tags.Name
            id            = cgw.id
            ip_address    = cgw.ip_address
            bgp_asn       = cgw.bgp_asn
          }
        ] :
        local.is_azure ? [
          for i, cgw in aws_customer_gateway.azure_gw : {
            resource_type = "aws_customer_gateway"
            name          = cgw.tags.Name
            id            = cgw.id
            ip_address    = cgw.ip_address
            bgp_asn       = cgw.bgp_asn
          }
        ] : []
      )
      vpn_connections = (
        local.is_gcp ? [
          for i, vpn in aws_vpn_connection.conn_to_gcp : {
            resource_type   = "aws_vpn_connection"
            name            = vpn.tags.Name
            id              = vpn.id
            tunnel1_address = vpn.tunnel1_address
            tunnel2_address = vpn.tunnel2_address
          }
        ] :
        local.is_azure ? [
          for i, vpn in aws_vpn_connection.conn_to_azure : {
            resource_type   = "aws_vpn_connection"
            name            = vpn.tags.Name
            id              = vpn.id
            tunnel1_address = vpn.tunnel1_address
            tunnel2_address = vpn.tunnel2_address
          }
        ] : []
      )
    }
    target_csp = merge(
      local.is_gcp ? {
        type = var.vpn_config.target_csp.type
        vpn_gateway = {
          resource_type = "google_compute_ha_vpn_gateway"
          name          = google_compute_ha_vpn_gateway.vpn_gw[0].name
          id            = google_compute_ha_vpn_gateway.vpn_gw[0].id
          network       = google_compute_ha_vpn_gateway.vpn_gw[0].network
          region        = google_compute_ha_vpn_gateway.vpn_gw[0].region
        }
        external_gateway = {
          resource_type   = "google_compute_external_vpn_gateway"
          name            = google_compute_external_vpn_gateway.aws_gw[0].name
          id              = google_compute_external_vpn_gateway.aws_gw[0].id
          redundancy_type = google_compute_external_vpn_gateway.aws_gw[0].redundancy_type
          description     = google_compute_external_vpn_gateway.aws_gw[0].description
          interfaces = [
            for iface in google_compute_external_vpn_gateway.aws_gw[0].interface : {
              id         = iface.id
              ip_address = iface.ip_address
            }
          ]
        }
        router = {
          resource_type = "google_compute_router"
          name          = google_compute_router.router[0].name
          id            = google_compute_router.router[0].id
          network       = google_compute_router.router[0].network
          bgp_asn       = var.vpn_config.target_csp.gcp.bgp_asn
        }
        tunnels = [
          for tunnel in google_compute_vpn_tunnel.vpn_tunnel : {
            name      = tunnel.name
            id        = tunnel.id
            peer_ip   = tunnel.peer_ip
            interface = tunnel.vpn_gateway_interface
          }
        ]
        interfaces = [
          for iface in google_compute_router_interface.router_interface : {
            name     = iface.name
            id       = iface.id
            ip_range = iface.ip_range
          }
        ]
        peers = [
          for peer in google_compute_router_peer.router_peer : {
            name     = peer.name
            id       = peer.id
            peer_ip  = peer.peer_ip_address
            peer_asn = peer.peer_asn
          }
        ]
      } : null,
      local.is_azure ? {
        type = var.vpn_config.target_csp.type
        vpn_gateway = try({
          resource_type = "azurerm_virtual_network_gateway"
          name          = azurerm_virtual_network_gateway.vpn[0].name
          id            = azurerm_virtual_network_gateway.vpn[0].id
          location      = azurerm_virtual_network_gateway.vpn[0].location
          sku           = azurerm_virtual_network_gateway.vpn[0].sku
        }, null)
        public_ips = try([
          for pip in azurerm_public_ip.vpn : {
            name       = pip.name
            id         = pip.id
            ip_address = pip.ip_address
          }
        ], [])
        connections = try([
          for conn in azurerm_virtual_network_gateway_connection.aws : {
            name       = conn.name
            id         = conn.id
            type       = conn.type
            enable_bgp = conn.enable_bgp
          }
        ], [])
        local_gateways = try([
          for lgw in azurerm_local_network_gateway.aws : {
            name            = lgw.name
            id              = lgw.id
            gateway_address = lgw.gateway_address
          }
        ], [])
      } : null
    )
  }
}

output "vpn_summary" {
  description = "Summary of VPN connection"
  value = {
    provider_type = var.vpn_config.target_csp.type
    aws_region    = var.vpn_config.aws.region
    target_region = local.csp_config.region
    connection_count = (
      local.is_gcp ? {
        customer_gateways = length(aws_customer_gateway.gcp_gw)
        vpn_connections   = length(aws_vpn_connection.conn_to_gcp)
      } :
      local.is_azure ? {
        customer_gateways      = length(aws_customer_gateway.azure_gw)
        vpn_connections        = length(aws_vpn_connection.conn_to_azure)
        local_network_gateways = length(azurerm_local_network_gateway.aws)
        azure_vpn_connections  = length(azurerm_virtual_network_gateway_connection.aws)
      } : null
    )
  }
}


# backup
#   target_csp = merge(
#     local.is_gcp ? {
#       type = var.vpn_config.target_csp.type
#       vpn_gateway = {
#         resource_type = "google_compute_ha_vpn_gateway"
#         name          = google_compute_ha_vpn_gateway.vpn_gw[0].name
#         id            = google_compute_ha_vpn_gateway.vpn_gw[0].id
#         network       = google_compute_ha_vpn_gateway.vpn_gw[0].network
#         region        = google_compute_ha_vpn_gateway.vpn_gw[0].region
#       }
#       external_gateway = {
#         resource_type   = "google_compute_external_vpn_gateway"
#         name            = google_compute_external_vpn_gateway.aws_gw[0].name
#         id              = google_compute_external_vpn_gateway.aws_gw[0].id
#         redundancy_type = google_compute_external_vpn_gateway.aws_gw[0].redundancy_type
#         description     = google_compute_external_vpn_gateway.aws_gw[0].description
#         interfaces = [
#           for iface in google_compute_external_vpn_gateway.aws_gw[0].interface : {
#             id         = iface.id
#             ip_address = iface.ip_address
#           }
#         ]
#       }
#       router = {
#         resource_type = "google_compute_router"
#         name          = google_compute_router.router[0].name
#         id            = google_compute_router.router[0].id
#         network       = google_compute_router.router[0].network
#         bgp_asn       = var.vpn_config.target_csp.gcp.bgp_asn
#       }
#       tunnels = [
#         for tunnel in google_compute_vpn_tunnel.vpn_tunnel : {
#           name      = tunnel.name
#           id        = tunnel.id
#           peer_ip   = tunnel.peer_ip
#           interface = tunnel.vpn_gateway_interface
#         }
#       ]
#       interfaces = [
#         for iface in google_compute_router_interface.router_interface : {
#           name     = iface.name
#           id       = iface.id
#           ip_range = iface.ip_range
#         }
#       ]
#       peers = [
#         for peer in google_compute_router_peer.router_peer : {
#           name     = peer.name
#           id       = peer.id
#           peer_ip  = peer.peer_ip_address
#           peer_asn = peer.peer_asn
#         }
#       ]
#     } : null,
#     local.is_azure ? {
#       type = var.vpn_config.target_csp.type
#       vpn_gateway = try({
#         resource_type = "azurerm_virtual_network_gateway"
#         name          = azurerm_virtual_network_gateway.vpn[0].name
#         id            = azurerm_virtual_network_gateway.vpn[0].id
#         location      = azurerm_virtual_network_gateway.vpn[0].location
#         sku           = azurerm_virtual_network_gateway.vpn[0].sku
#       }, null)
#       public_ips = try([
#         for pip in azurerm_public_ip.vpn : {
#           name       = pip.name
#           id         = pip.id
#           ip_address = pip.ip_address
#         }
#       ], [])
#       connections = try([
#         for conn in azurerm_virtual_network_gateway_connection.aws : {
#           name       = conn.name
#           id         = conn.id
#           type       = conn.type
#           enable_bgp = conn.enable_bgp
#         }
#       ], [])
#       local_gateways = try([
#         for lgw in azurerm_local_network_gateway.aws : {
#           name            = lgw.name
#           id              = lgw.id
#           gateway_address = lgw.gateway_address
#         }
#       ], [])
#     } : null
#   )
# }
