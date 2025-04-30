output "vpn_info" {
  description = "VPN connection information"
  value = {
    aws = {
      customer_gateways = try([
        for i, cgw in aws_customer_gateway.alibaba_gw : {
          resource_type = "aws_customer_gateway"
          name          = cgw.tags.Name
          id            = cgw.id
          ip_address    = cgw.ip_address
          bgp_asn       = cgw.bgp_asn
        }
      ], [])
      vpn_connections = try([
        for i, vpn in aws_vpn_connection.to_alibaba : {
          resource_type   = "aws_vpn_connection"
          name            = vpn.tags.Name
          id              = vpn.id
          tunnel1_address = vpn.tunnel1_address
          tunnel2_address = vpn.tunnel2_address
        }
      ], [])
    }
    alibaba = {
      vpn_gateway = try({
        resource_type                 = "alicloud_vpn_gateway"
        id                            = alicloud_vpn_gateway.vpn_gw.id
        name                          = alicloud_vpn_gateway.vpn_gw.name
        internet_ip                   = alicloud_vpn_gateway.vpn_gw.internet_ip
        disaster_recovery_internet_ip = alicloud_vpn_gateway.vpn_gw.disaster_recovery_internet_ip
      }, null)
      customer_gateways = try([
        for cgw in alicloud_vpn_customer_gateway.aws_gw : {
          resource_type = "alicloud_vpn_customer_gateway"
          id            = cgw.id
          ip_address    = cgw.ip_address
          asn           = cgw.asn
        }
      ], [])
      vpn_connections = try([
        for conn in alicloud_vpn_connection.to_aws : {
          resource_type = "alicloud_vpn_connection"
          id            = conn.id
          bgp_status    = conn.bgp_config.status
          tunnels = try([
            for tos in conn.tunnel_options_specification : {
              resource_type = "alicloud_vpn_tunnel_options"
              id            = tos.tunnel_id
              state         = tos.state
              status        = tos.status
              bgp_status    = tos.bgp_status
              peer_asn      = tos.peer_asn
              peer_bgp_ip   = tos.peer_bgp_ip
            }
          ], [])
        }
      ], [])
      bgp_asn = var.bgp_asn
    }
  }
}
