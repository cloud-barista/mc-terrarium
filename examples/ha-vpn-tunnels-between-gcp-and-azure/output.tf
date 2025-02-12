output "gcp_router_id" {
  value = google_compute_router.my-gcp-router-main.id
}

output "gcp_ha_vpn_gateway_id" {
  value = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.id
}

output "gcp_external_vpn_gateway_id" {
  value = google_compute_external_vpn_gateway.my-gcp-peer-vpn-gateway.id
}

output "gcp_vpn_tunnel_1_id" {
  value = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-1.id
}

output "gcp_vpn_tunnel_2_id" {
  value = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-2.id
}

output "gcp_router_interface_1_id" {
  value = google_compute_router_interface.my-gcp-router-interface-1.id
}

output "gcp_router_interface_2_id" {
  value = google_compute_router_interface.my-gcp-router-interface-2.id
}

output "gcp_router_peer_1_id" {
  value = google_compute_router_peer.my-gcp-router-peer-1.id
}

output "gcp_router_peer_2_id" {
  value = google_compute_router_peer.my-gcp-router-peer-2.id
}

output "azure_gw_subnet_id" {
  value = azurerm_subnet.my-azure-gw-subnet.id
}

output "azure_vpn_gw_pub_ip_1" {
  value = azurerm_public_ip.my-azure-public-ip-1.ip_address
}

output "azure_vpn_gw_pub_ip_2" {
  value = azurerm_public_ip.my-azure-public-ip-2.ip_address
}

output "azure_vpn_gw_id" {
  value = azurerm_virtual_network_gateway.my-azure-vpn-gateway.id
}

output "azurerm_local_network_gateway_peer_gw_1_id" {
  value = azurerm_local_network_gateway.my-azure-local-gateway-1.id
}
output "azurerm_local_network_gateway_peer_gw_2_id" {
  value = azurerm_local_network_gateway.my-azure-local-gateway-2.id
}

output "azurerm_virtual_network_gateway_connection_1_id" {
  value = azurerm_virtual_network_gateway_connection.my-azure-cx-1.id
}

output "azurerm_virtual_network_gateway_connection_2_id" {
  value = azurerm_virtual_network_gateway_connection.my-azure-cx-2.id
}


output "vpn_info" {
  description = "VPN configuration details for Azure and GCP"
  value = {
    azure = {
      virtual_network_gateway = {
        resource_type = "azurerm_virtual_network_gateway"
        name          = azurerm_virtual_network_gateway.my-azure-vpn-gateway.name
        id            = azurerm_virtual_network_gateway.my-azure-vpn-gateway.id
        location      = azurerm_virtual_network_gateway.my-azure-vpn-gateway.location
        vpn_type      = azurerm_virtual_network_gateway.my-azure-vpn-gateway.vpn_type
        sku           = azurerm_virtual_network_gateway.my-azure-vpn-gateway.sku
        bgp_settings = {
          asn = azurerm_virtual_network_gateway.my-azure-vpn-gateway.bgp_settings[0].asn
          peering_addresses = [
            {
              ip_configuration = "vnetGatewayConfig1"
              address          = azurerm_virtual_network_gateway.my-azure-vpn-gateway.bgp_settings[0].peering_addresses[0].default_addresses[0]
            },
            {
              ip_configuration = "vnetGatewayConfig2"
              address          = azurerm_virtual_network_gateway.my-azure-vpn-gateway.bgp_settings[0].peering_addresses[1].default_addresses[0]
            }
          ]
        }
      }
      public_ips = {
        ip1 = {
          resource_type = "azurerm_public_ip"
          name          = azurerm_public_ip.my-azure-public-ip-1.name
          id            = azurerm_public_ip.my-azure-public-ip-1.id
          ip_address    = azurerm_public_ip.my-azure-public-ip-1.ip_address
        }
        ip2 = {
          resource_type = "azurerm_public_ip"
          name          = azurerm_public_ip.my-azure-public-ip-2.name
          id            = azurerm_public_ip.my-azure-public-ip-2.id
          ip_address    = azurerm_public_ip.my-azure-public-ip-2.ip_address
        }
      }
      connections = [
        {
          resource_type = "azurerm_virtual_network_gateway_connection"
          name          = azurerm_virtual_network_gateway_connection.my-azure-cx-1.name
          id            = azurerm_virtual_network_gateway_connection.my-azure-cx-1.id
          type          = azurerm_virtual_network_gateway_connection.my-azure-cx-1.type
          enable_bgp    = azurerm_virtual_network_gateway_connection.my-azure-cx-1.enable_bgp
        },
        {
          resource_type = "azurerm_virtual_network_gateway_connection"
          name          = azurerm_virtual_network_gateway_connection.my-azure-cx-2.name
          id            = azurerm_virtual_network_gateway_connection.my-azure-cx-2.id
          type          = azurerm_virtual_network_gateway_connection.my-azure-cx-2.type
          enable_bgp    = azurerm_virtual_network_gateway_connection.my-azure-cx-2.enable_bgp
        }
      ]
    }
    gcp = {
      router = {
        resource_type = "google_compute_router"
        name          = google_compute_router.my-gcp-router-main.name
        id            = google_compute_router.my-gcp-router-main.id
        network       = google_compute_router.my-gcp-router-main.network
        bgp = {
          asn            = google_compute_router.my-gcp-router-main.bgp[0].asn
          advertise_mode = google_compute_router.my-gcp-router-main.bgp[0].advertise_mode
        }
      }
      ha_vpn_gateway = {
        resource_type = "google_compute_ha_vpn_gateway"
        name          = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.name
        id            = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.id
        network       = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.network
        interfaces    = google_compute_ha_vpn_gateway.my-gcp-ha-vpn-gateway.vpn_interfaces
      }
      vpn_tunnels = [
        {
          resource_type = "google_compute_vpn_tunnel"
          name          = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-1.name
          id            = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-1.id
          router        = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-1.router
          interface     = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-1.vpn_gateway_interface
        },
        {
          resource_type = "google_compute_vpn_tunnel"
          name          = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-2.name
          id            = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-2.id
          router        = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-2.router
          interface     = google_compute_vpn_tunnel.my-gcp-vpn-tunnel-2.vpn_gateway_interface
        }
      ]
      bgp_peers = [
        {
          resource_type  = "google_compute_router_peer"
          name           = google_compute_router_peer.my-gcp-router-peer-1.name
          peer_ip        = google_compute_router_peer.my-gcp-router-peer-1.peer_ip_address
          peer_asn       = google_compute_router_peer.my-gcp-router-peer-1.peer_asn
          interface_name = google_compute_router_peer.my-gcp-router-peer-1.interface
        },
        {
          resource_type  = "google_compute_router_peer"
          name           = google_compute_router_peer.my-gcp-router-peer-2.name
          peer_ip        = google_compute_router_peer.my-gcp-router-peer-2.peer_ip_address
          peer_asn       = google_compute_router_peer.my-gcp-router-peer-2.peer_asn
          interface_name = google_compute_router_peer.my-gcp-router-peer-2.interface
        }
      ]
    }
  }
}
