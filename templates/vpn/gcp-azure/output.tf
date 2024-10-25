
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


output "vpn_info" {
  description = "VPN configuration details for Azure and GCP"
  value = {
    terrarium = {
      id = var.terrarium-id
    }
    azure = {
      virtual_network_gateway = {
        resource_type = "azurerm_virtual_network_gateway"
        name          = azurerm_virtual_network_gateway.vpn_gw_1.name
        id            = azurerm_virtual_network_gateway.vpn_gw_1.id
        location      = azurerm_virtual_network_gateway.vpn_gw_1.location
        vpn_type      = azurerm_virtual_network_gateway.vpn_gw_1.vpn_type
        sku           = azurerm_virtual_network_gateway.vpn_gw_1.sku
        bgp_settings = {
          asn = azurerm_virtual_network_gateway.vpn_gw_1.bgp_settings[0].asn
          peering_addresses = [
            {
              ip_configuration = "${var.terrarium-id}-vnetGatewayConfig1"
              address         = azurerm_virtual_network_gateway.vpn_gw_1.bgp_settings[0].peering_addresses[0].apipa_addresses[0]
            },
            {
              ip_configuration = "${var.terrarium-id}-vnetGatewayConfig2"
              address         = azurerm_virtual_network_gateway.vpn_gw_1.bgp_settings[0].peering_addresses[1].apipa_addresses[0]
            }
          ]
        }
      }
      public_ips = {
        ip1 = {
          resource_type = "azurerm_public_ip"
          name         = azurerm_public_ip.vpn_gw_pub_ip_1.name
          id           = azurerm_public_ip.vpn_gw_pub_ip_1.id
          ip_address   = azurerm_public_ip.vpn_gw_pub_ip_1.ip_address
        }
        ip2 = {
          resource_type = "azurerm_public_ip"
          name         = azurerm_public_ip.vpn_gw_pub_ip_2.name
          id           = azurerm_public_ip.vpn_gw_pub_ip_2.id
          ip_address   = azurerm_public_ip.vpn_gw_pub_ip_2.ip_address
        }
      }
      connections = [
        {
          resource_type = "azurerm_virtual_network_gateway_connection"
          name         = azurerm_virtual_network_gateway_connection.gcp_and_azure_cnx_1.name
          id           = azurerm_virtual_network_gateway_connection.gcp_and_azure_cnx_1.id
          type         = azurerm_virtual_network_gateway_connection.gcp_and_azure_cnx_1.type
          enable_bgp   = azurerm_virtual_network_gateway_connection.gcp_and_azure_cnx_1.enable_bgp
        },
        {
          resource_type = "azurerm_virtual_network_gateway_connection"
          name         = azurerm_virtual_network_gateway_connection.gcp_and_azure_cnx_2.name
          id           = azurerm_virtual_network_gateway_connection.gcp_and_azure_cnx_2.id
          type         = azurerm_virtual_network_gateway_connection.gcp_and_azure_cnx_2.type
          enable_bgp   = azurerm_virtual_network_gateway_connection.gcp_and_azure_cnx_2.enable_bgp
        }
      ]
    }
    gcp = {
      router = {
        resource_type = "google_compute_router"
        name         = google_compute_router.router_1.name
        id           = google_compute_router.router_1.id
        network      = google_compute_router.router_1.network
        bgp = {
          asn             = google_compute_router.router_1.bgp[0].asn
          advertise_mode  = google_compute_router.router_1.bgp[0].advertise_mode
        }
      }
      ha_vpn_gateway = {
        resource_type = "google_compute_ha_vpn_gateway"
        name         = google_compute_ha_vpn_gateway.ha_vpn_gw_1.name
        id           = google_compute_ha_vpn_gateway.ha_vpn_gw_1.id
        network      = google_compute_ha_vpn_gateway.ha_vpn_gw_1.network
        interfaces   = google_compute_ha_vpn_gateway.ha_vpn_gw_1.vpn_interfaces
      }
      vpn_tunnels = [
        {
          resource_type = "google_compute_vpn_tunnel"
          name         = google_compute_vpn_tunnel.vpn_tunnel_1.name
          id           = google_compute_vpn_tunnel.vpn_tunnel_1.id
          router       = google_compute_vpn_tunnel.vpn_tunnel_1.router
          interface    = google_compute_vpn_tunnel.vpn_tunnel_1.vpn_gateway_interface
        },
        {
          resource_type = "google_compute_vpn_tunnel"
          name         = google_compute_vpn_tunnel.vpn_tunnel_2.name
          id           = google_compute_vpn_tunnel.vpn_tunnel_2.id
          router       = google_compute_vpn_tunnel.vpn_tunnel_2.router
          interface    = google_compute_vpn_tunnel.vpn_tunnel_2.vpn_gateway_interface
        }
      ]
      bgp_peers = [
        {
          resource_type   = "google_compute_router_peer"
          name           = google_compute_router_peer.router_peer_1.name
          peer_ip        = google_compute_router_peer.router_peer_1.peer_ip_address
          peer_asn       = google_compute_router_peer.router_peer_1.peer_asn
          interface_name = google_compute_router_peer.router_peer_1.interface
        },
        {
          resource_type   = "google_compute_router_peer"
          name           = google_compute_router_peer.router_peer_2.name
          peer_ip        = google_compute_router_peer.router_peer_2.peer_ip_address
          peer_asn       = google_compute_router_peer.router_peer_2.peer_asn
          interface_name = google_compute_router_peer.router_peer_2.interface
        }
      ]
    }
  }
}