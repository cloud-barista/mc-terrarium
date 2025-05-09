output "vpn_info" {
  description = "VPN connection information"
  value = {
    aws = {
      customer_gateways = [
        for i, cgw in aws_customer_gateway.ibm_gw : {
          resource_type = "aws_customer_gateway"
          name          = try(cgw.tags.Name, "")
          id            = try(cgw.id, "")
          ip_address    = try(cgw.ip_address, "")
          bgp_asn       = try(cgw.bgp_asn, "")
        }
      ]
      vpn_connections = [
        for i, vpn in aws_vpn_connection.to_ibm : {
          resource_type   = "aws_vpn_connection"
          name            = try(vpn.tags.Name, "")
          id              = try(vpn.id, "")
          tunnel1_address = try(vpn.tunnel1_address, "")
          tunnel2_address = try(vpn.tunnel2_address, "")
        }
      ]
    }
    ibm = {
      vpn_gateway = {
        resource_type = try(ibm_is_vpn_gateway.vpn_gw.resource_type, "")
        name          = try(ibm_is_vpn_gateway.vpn_gw.name, "")
        id            = try(ibm_is_vpn_gateway.vpn_gw.id, "")
        public_ip_1   = try(ibm_is_vpn_gateway.vpn_gw.public_ip_address, "")
        public_ip_2   = try(ibm_is_vpn_gateway.vpn_gw.public_ip_address2, "")
      }
      vpn_connections = [
        for conn in ibm_is_vpn_gateway_connection.to_aws : {
          resource_type      = try(conn.resource_type, "")
          name               = try(conn.name, "")
          id                 = try(conn.id, "")
          crn                = try(conn.crn, "")
          gateway_connection = try(conn.gateway_connection, "")
          mode               = try(conn.mode, "")
          status             = try(conn.status, "")
          status_reasons = [
            for reason in conn.status_reasons : {
              code      = try(reason.code, "")
              message   = try(reason.message, "")
              more_info = try(reason.more_info, "")
            }
          ]
          tunnels = [
            for tunnel in conn.tunnels : {
              resource_type = try(tunnel.resource_type, "")
              address       = try(tunnel.address, "")
            }
          ]
        }
      ]
    }
  }
}
