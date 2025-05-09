output "vpn_info" {
  description = "VPN connection information"
  value = {
    aws = {
      customer_gateways = [
        for i, cgw in aws_customer_gateway.alibaba_gw : {
          resource_type = "aws_customer_gateway"
          id            = try(cgw.id, "")
          name          = try(cgw.tags.Name, "")
          ip_address    = try(cgw.ip_address, "")
          bgp_asn       = try(cgw.bgp_asn, "")
        }
      ]
      vpn_connections = [
        for i, vpn in aws_vpn_connection.to_alibaba : {
          resource_type   = "aws_vpn_connection"
          id              = try(vpn.id, "")
          name            = try(vpn.tags.Name, "")
          tunnel1_address = try(vpn.tunnel1_address, "")
          tunnel2_address = try(vpn.tunnel2_address, "")
        }
      ]
    }
    alibaba = {
      vpn_gateway = {
        resource_type                 = "alicloud_vpn_gateway"
        id                            = try(alicloud_vpn_gateway.vpn_gw.id, "")
        internet_ip                   = try(alicloud_vpn_gateway.vpn_gw.internet_ip, "")
        disaster_recovery_internet_ip = try(alicloud_vpn_gateway.vpn_gw.disaster_recovery_internet_ip, "")
        # name                          = try(alicloud_vpn_gateway.vpn_gw.name) # Deprecated
      }
      customer_gateways = [
        for cgw in alicloud_vpn_customer_gateway.aws_gw : {
          resource_type = "alicloud_vpn_customer_gateway"
          id            = try(cgw.id, "")
          ip_address    = try(cgw.ip_address, "")
          asn           = try(cgw.asn, "")
        }
      ]
      vpn_connections = [
        for conn in alicloud_vpn_connection.to_aws : {
          resource_type = "alicloud_vpn_connection"
          id            = try(conn.id, "")
          bgp_status    = try(conn.bgp_config.status, "")
          tunnels = [
            for tos in conn.tunnel_options_specification : {
              resource_type = "alicloud_vpn_tunnel_options"
              id            = try(tos.tunnel_id, "")
              state         = try(tos.state, "")
              status        = try(tos.status, "")
              bgp_status    = try(tos.bgp_status, "")
              peer_asn      = try(tos.peer_asn, "")
              peer_bgp_ip   = try(tos.peer_bgp_ip, "")
            }
          ]
        }
      ]
      bgp_asn = var.bgp_asn
    }
  }
}
