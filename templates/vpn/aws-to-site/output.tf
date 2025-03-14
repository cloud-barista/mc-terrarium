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
        ] :
        local.is_alibaba ? [
          for i, cgw in aws_customer_gateway.alibaba_gw : {
            resource_type = "aws_customer_gateway"
            name          = cgw.tags.Name
            id            = cgw.id
            ip_address    = cgw.ip_address
            bgp_asn       = cgw.bgp_asn
          }
        ] :
        local.is_ibm ? [
          for i, cgw in aws_customer_gateway.ibm_gw : {
            resource_type = "aws_customer_gateway"
            name          = cgw.tags.Name
            id            = cgw.id
            ip_address    = cgw.ip_address
            bgp_asn       = cgw.bgp_asn
          }
        ] :
        local.is_tencent ? [
          for i, cgw in aws_customer_gateway.tencent_gw : {
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
          for i, vpn in aws_vpn_connection.to_gcp : {
            resource_type   = "aws_vpn_connection"
            name            = vpn.tags.Name
            id              = vpn.id
            tunnel1_address = vpn.tunnel1_address
            tunnel2_address = vpn.tunnel2_address
          }
        ] :
        local.is_azure ? [
          for i, vpn in aws_vpn_connection.to_azure : {
            resource_type   = "aws_vpn_connection"
            name            = vpn.tags.Name
            id              = vpn.id
            tunnel1_address = vpn.tunnel1_address
            tunnel2_address = vpn.tunnel2_address
          }
        ] :
        local.is_alibaba ? [
          for i, vpn in aws_vpn_connection.to_alibaba : {
            resource_type   = "aws_vpn_connection"
            name            = vpn.tags.Name
            id              = vpn.id
            tunnel1_address = vpn.tunnel1_address
            tunnel2_address = vpn.tunnel2_address
          }
        ] :
        local.is_ibm ? [
          for i, vpn in aws_vpn_connection.to_ibm : {
            resource_type   = "aws_vpn_connection"
            name            = vpn.tags.Name
            id              = vpn.id
            tunnel1_address = vpn.tunnel1_address
            tunnel2_address = vpn.tunnel2_address
          }
        ] :
        local.is_tencent ? [
          for i, vpn in aws_vpn_connection.to_tencent : {
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
          for tunnel in google_compute_vpn_tunnel.to_aws : {
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
          name          = azurerm_virtual_network_gateway.vpn_gw[0].name
          id            = azurerm_virtual_network_gateway.vpn_gw[0].id
          location      = azurerm_virtual_network_gateway.vpn_gw[0].location
          sku           = azurerm_virtual_network_gateway.vpn_gw[0].sku
        }, null)
        public_ips = try([
          for pip in azurerm_public_ip.pub_ip : {
            name       = pip.name
            id         = pip.id
            ip_address = pip.ip_address
          }
        ], [])
        connections = try([
          for conn in azurerm_virtual_network_gateway_connection.to_aws : {
            name       = conn.name
            id         = conn.id
            type       = conn.type
            enable_bgp = conn.enable_bgp
          }
        ], [])
        local_gateways = try([
          for lgw in azurerm_local_network_gateway.aws_gw : {
            name            = lgw.name
            id              = lgw.id
            gateway_address = lgw.gateway_address
          }
        ], [])
      } : null,
      local.is_alibaba ? {
        type = var.vpn_config.target_csp.type
        vpn_gateway = try({
          id                            = alicloud_vpn_gateway.vpn_gw[0].id
          internet_ip                   = alicloud_vpn_gateway.vpn_gw[0].internet_ip
          disaster_recovery_internet_ip = alicloud_vpn_gateway.vpn_gw[0].disaster_recovery_internet_ip
        }, null)
        customer_gateways = try([
          for cgw in alicloud_vpn_customer_gateway.aws_gw : {
            id         = cgw.id
            ip_address = cgw.ip_address
            asn        = cgw.asn
          }
        ], [])
        vpn_connections = try([
          for conn in alicloud_vpn_connection.to_aws : {
            id         = conn.id
            bgp_status = conn.bgp_config.status
            tunnels = try([
              for tos in conn.tunnel_options_specification : {
                id          = tos.tunnel_id
                state       = tos.state
                status      = tos.status
                bsp_status  = tos.bgp_status
                peer_asn    = tos.peer_asn
                peer_bgp_ip = tos.peer_bgp_ip
              }
            ], [])
          }
        ], [])
      } : null,
      local.is_ibm ? {
        type = var.vpn_config.target_csp.type
        vpn_gateway = try({
          resource_type = "ibm_is_vpn_gateway"
          name          = ibm_is_vpn_gateway.vpn_gw[0].name
          id            = ibm_is_vpn_gateway.vpn_gw[0].id
          public_ip_1   = ibm_is_vpn_gateway.vpn_gw[0].public_ip_address
          public_ip_2   = ibm_is_vpn_gateway.vpn_gw[0].public_ip_address2
        }, null)
        vpn_connections = try([
          for conn in ibm_is_vpn_gateway_connection.to_aws : {
            name          = conn.name
            id            = conn.id
            preshared_key = nonsensitive(conn.preshared_key)
            local_cidrs   = conn.local[0].cidrs
            peer_address  = conn.peer[0].address
            peer_cidrs    = conn.peer[0].cidrs
          }
        ], [])
      } : null,
      local.is_tencent ? {
        type = var.vpn_config.target_csp.type
        vpn_gateway = try({
          resource_type = "tencentcloud_vpn_gateway"
          name          = tencentcloud_vpn_gateway.vpn_gw[0].name
          id            = tencentcloud_vpn_gateway.vpn_gw[0].id
          public_ips    = tencentcloud_vpn_gateway.vpn_gw[0].public_ip_address
        }, null)
        customer_gateways = try([
          for cgw in tencentcloud_vpn_customer_gateway.aws_gw : {
            name              = cgw.name
            id                = cgw.id
            public_ip_address = cgw.public_ip_address
          }
        ], [])
        vpn_connections = try([
          for conn in tencentcloud_vpn_connection.to_aws : {
            name                = conn.name
            id                  = conn.id
            vpc_cidr_block      = conn.vpc_cidr_block
            customer_cidr_block = conn.customer_gateway_cidr_block
            local_bgp_ip        = conn.bgp_config.local_bgp_ip
            remote_bgp_ip       = conn.bgp_config.remote_bgp_ip
            tunnel_cidr         = conn.bgp_config.tunnel_cidr
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
        vpn_connections   = length(aws_vpn_connection.to_gcp)
      } :
      local.is_azure ? {
        customer_gateways      = length(aws_customer_gateway.azure_gw)
        vpn_connections        = length(aws_vpn_connection.to_azure)
        local_network_gateways = length(azurerm_local_network_gateway.aws_gw)
        azure_vpn_connections  = length(azurerm_virtual_network_gateway_connection.to_aws)
      } :
      local.is_alibaba ? {
        vpn_gateways      = length(alicloud_vpn_gateway.vpn_gw)
        customer_gateways = length(alicloud_vpn_customer_gateway.aws_gw)
        vpn_connections   = length(alicloud_vpn_connection.to_aws)
      } :
      local.is_ibm ? {
        vpn_gateways    = length(ibm_is_vpn_gateway.vpn_gw)
        vpn_connections = length(ibm_is_vpn_gateway_connection.to_aws)
      } :
      local.is_tencent ? {
        vpn_gateways      = length(tencentcloud_vpn_gateway.vpn_gw)
        customer_gateways = length(tencentcloud_vpn_customer_gateway.aws_gw)
        vpn_connections   = length(tencentcloud_vpn_connection.to_aws)
      } : null
    )
  }
}

# output "vpn_output_debug" {
#   description = "All VPN connection information including sensitive data for debugging"
#   value = {
#     aws_side = {
#       vpc = {
#         id         = data.aws_vpc.existing.id
#         cidr_block = data.aws_vpc.existing.cidr_block
#         subnets = [for subnet in data.aws_subnet.details : {
#           id                = subnet.id
#           cidr_block        = subnet.cidr_block
#           vpc_id            = subnet.vpc_id
#           availability_zone = subnet.availability_zone
#         }]
#       }
#       vpn_gateway = {
#         complete_data = aws_vpn_gateway.vpn_gw
#         tags          = aws_vpn_gateway.vpn_gw.tags
#       }
#       customer_gateways = [for gw in aws_customer_gateway.alibaba_gw : {
#         complete_data = gw
#         sensitive_data = {
#           # certificate = gw.certificate
#           device_name = gw.device_name
#         }
#       }]
#       vpn_connections = [for conn in aws_vpn_connection.to_alibaba : {
#         complete_data = conn
#         tunnel1 = {
#           address            = conn.tunnel1_address
#           bgp_asn            = conn.tunnel1_bgp_asn
#           bgp_holdtime       = conn.tunnel1_bgp_holdtime
#           cgw_inside_address = conn.tunnel1_cgw_inside_address
#           vgw_inside_address = conn.tunnel1_vgw_inside_address
#           preshared_key      = nonsensitive(conn.tunnel1_preshared_key)
#           inside_cidr        = conn.tunnel1_inside_cidr
#         }
#         tunnel2 = {
#           address            = conn.tunnel2_address
#           bgp_asn            = conn.tunnel2_bgp_asn
#           bgp_holdtime       = conn.tunnel2_bgp_holdtime
#           cgw_inside_address = conn.tunnel2_cgw_inside_address
#           vgw_inside_address = conn.tunnel2_vgw_inside_address
#           preshared_key      = nonsensitive(conn.tunnel2_preshared_key)
#           inside_cidr        = conn.tunnel2_inside_cidr
#         }
#       }]
#     }

#     alibaba_side = local.is_alibaba ? {
#       vpc = {
#         info = data.alicloud_vpcs.existing
#         vswitches = [for vs in data.alicloud_vswitches.existing[0].vswitches : {
#           id          = vs.id
#           cidr_block  = vs.cidr_block
#           zone_id     = vs.zone_id
#           name        = vs.name
#           description = vs.description
#         }]
#       }
#       vpn_gateway = {
#         complete_data = alicloud_vpn_gateway.vpn_gw[0]
#         details = {
#           id                            = alicloud_vpn_gateway.vpn_gw[0].id
#           status                        = alicloud_vpn_gateway.vpn_gw[0].status
#           internet_ip                   = alicloud_vpn_gateway.vpn_gw[0].internet_ip
#           disaster_recovery_internet_ip = alicloud_vpn_gateway.vpn_gw[0].disaster_recovery_internet_ip
#           # spec                          = alicloud_vpn_gateway.vpn_gw[0].spec
#         }
#       }
#       customer_gateways = [for gw in alicloud_vpn_customer_gateway.aws_gw : {
#         complete_data = gw
#         details = {
#           id          = gw.id
#           name        = gw.customer_gateway_name
#           ip_address  = gw.ip_address
#           asn         = gw.asn
#           description = gw.description
#           create_time = gw.create_time
#         }
#       }]
#       vpn_connections = [for conn in alicloud_vpn_connection.to_aws : {
#         complete_data = conn
#         details = {
#           id                 = conn.id
#           name               = conn.vpn_connection_name
#           status             = conn.status
#           local_subnet       = conn.local_subnet
#           remote_subnet      = conn.remote_subnet
#           create_time        = conn.create_time
#           effect_immediately = conn.effect_immediately
#         }
#         tunnel_specs = [for tunnel in conn.tunnel_options_specification : {
#           tunnel_id    = tunnel.tunnel_id
#           role         = tunnel.role
#           status       = tunnel.status
#           ike_config   = tunnel.tunnel_ike_config
#           ipsec_config = tunnel.tunnel_ipsec_config
#           bgp_config   = tunnel.tunnel_bgp_config
#           psk          = nonsensitive(tunnel.tunnel_ike_config[0].psk)
#           # bgp_status   = tunnel.bgp_status
#         }]
#       }]
#     } : null

#     input_configuration = nonsensitive({
#       terrarium_id = var.vpn_config.terrarium_id
#       aws_config   = var.vpn_config.aws
#       csp_config   = var.vpn_config.target_csp
#     })
#   }

#   sensitive = true
# }

