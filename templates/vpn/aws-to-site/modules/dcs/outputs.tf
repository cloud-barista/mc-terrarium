output "vpn_info" {
  description = "VPN connection information"
  value = {
    aws = {
      customer_gateways = [
        {
          resource_type = "aws_customer_gateway"
          name          = try(aws_customer_gateway.cgw.tags.Name, "")
          id            = try(aws_customer_gateway.cgw.id, "")
          ip_address    = try(aws_customer_gateway.cgw.ip_address, "")
          bgp_asn       = try(aws_customer_gateway.cgw.bgp_asn, "")
        }
      ]
      vpn_connections = [
        {
          resource_type   = "aws_vpn_connection"
          name            = try(aws_vpn_connection.to_dcs.tags.Name, "")
          id              = try(aws_vpn_connection.to_dcs.id, "")
          tunnel1_address = try(aws_vpn_connection.to_dcs.tunnel1_address, "")
          tunnel2_address = try(aws_vpn_connection.to_dcs.tunnel2_address, "")
        }
      ]
    }
    dcs = {
      vpn_service = {
        resource_type = "openstack_vpnaas_service_v2"
        name          = try(openstack_vpnaas_service_v2.vpn.name, "")
        id            = try(openstack_vpnaas_service_v2.vpn.id, "")
        router_id     = try(openstack_vpnaas_service_v2.vpn.router_id, "")
        external_ip   = try(openstack_vpnaas_service_v2.vpn.external_v4_ip, "")
      }
      site_connections = [
        {
          resource_type = "openstack_vpnaas_site_connection_v2"
          name          = try(openstack_vpnaas_site_connection_v2.to_aws1.name, "")
          id            = try(openstack_vpnaas_site_connection_v2.to_aws1.id, "")
          peer_address  = try(openstack_vpnaas_site_connection_v2.to_aws1.peer_address, "")
          peer_id       = try(openstack_vpnaas_site_connection_v2.to_aws1.peer_id, "")
        },
        {
          resource_type = "openstack_vpnaas_site_connection_v2"
          name          = try(openstack_vpnaas_site_connection_v2.to_aws2.name, "")
          id            = try(openstack_vpnaas_site_connection_v2.to_aws2.id, "")
          peer_address  = try(openstack_vpnaas_site_connection_v2.to_aws2.peer_address, "")
          peer_id       = try(openstack_vpnaas_site_connection_v2.to_aws2.peer_id, "")
        }
      ]
    }
  }
}
