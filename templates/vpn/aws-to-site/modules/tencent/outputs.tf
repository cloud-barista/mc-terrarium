output "vpn_info" {
  description = "VPN connection information"
  value = {
    aws = {
      customer_gateways = [
        for i, cgw in aws_customer_gateway.tencent_gw : {
          resource_type = "aws_customer_gateway"
          name          = try(cgw.tags.Name, "")
          id            = try(cgw.id, "")
          ip_address    = try(cgw.ip_address, "")
          bgp_asn       = try(cgw.bgp_asn, "")
        }
      ]
      vpn_connections = [
        for i, vpn in aws_vpn_connection.to_tencent : {
          resource_type   = "aws_vpn_connection"
          name            = try(vpn.tags.Name, "")
          id              = try(vpn.id, "")
          tunnel1_address = try(vpn.tunnel1_address, "")
          tunnel2_address = try(vpn.tunnel2_address, "")
        }
      ]
    }
    tencent = {
      vpn_gateways = [
        for vpn_gw in tencentcloud_vpn_gateway.vpn_gw : {
          resource_type = "tencentcloud_vpn_gateway"
          name          = try(vpn_gw.name, "")
          id            = try(vpn_gw.id, "")
          vpc_id        = try(vpn_gw.vpc_id, "")
          public_ip     = try(vpn_gw.public_ip_address, "")
        }
      ]
      customer_gateways = [
        for cgw in tencentcloud_vpn_customer_gateway.aws_gw : {
          resource_type     = "tencentcloud_vpn_customer_gateway"
          name              = try(cgw.name, "")
          id                = try(cgw.id, "")
          public_ip_address = try(cgw.public_ip_address, "")
        }
      ]
      vpn_connections = [
        for conn in tencentcloud_vpn_connection.to_aws : {
          resource_type          = "tencentcloud_vpn_connection"
          name                   = try(conn.name, null)
          id                     = try(conn.id, null)
          vpc_id                 = try(conn.vpc_id, null)
          vpn_gateway_id         = try(conn.vpn_gateway_id, null)
          customer_gatway_id     = try(conn.customer_gateway_id, null)
          ike_local_address      = try(conn.ike_local_address, null)
          ike_remote_address     = try(conn.ike_remote_address, null)
          health_check_local_ip  = try(conn.health_check_local_ip, null)
          health_check_remote_ip = try(conn.health_check_remote_ip, null)
        }
      ]
    }
  }
}
