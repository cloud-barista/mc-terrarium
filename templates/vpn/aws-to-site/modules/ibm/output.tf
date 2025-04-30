output "vpn_info" {
  description = "VPN connection information"
  value = {
    aws = {
      customer_gateways = try([
        for i, cgw in aws_customer_gateway.ibm_gw : {
          resource_type = "aws_customer_gateway"
          name          = cgw.tags.Name
          id            = cgw.id
          ip_address    = cgw.ip_address
          bgp_asn       = cgw.bgp_asn
        }
      ], [])
      vpn_connections = try([
        for i, vpn in aws_vpn_connection.to_ibm : {
          resource_type   = "aws_vpn_connection"
          name            = vpn.tags.Name
          id              = vpn.id
          tunnel1_address = vpn.tunnel1_address
          tunnel2_address = vpn.tunnel2_address
        }
      ], [])
    }
    ibm = {
      vpn_gateway = try({
        resource_type = ibm_is_vpn_gateway.vpn_gw.resource_type
        name          = ibm_is_vpn_gateway.vpn_gw.name
        id            = ibm_is_vpn_gateway.vpn_gw.id
        public_ip_1   = ibm_is_vpn_gateway.vpn_gw.public_ip_address
        public_ip_2   = ibm_is_vpn_gateway.vpn_gw.public_ip_address2
      }, null)
      vpn_connections = try([
        for conn in ibm_is_vpn_gateway_connection.to_aws : {
          resource_type      = conn.resource_type
          name               = conn.name
          id                 = conn.id
          crn                = conn.crn
          gateway_connection = conn.gateway_connection
          mode               = conn.mode
          status             = conn.status
          status_reasons = try([
            for reason in conn.status_reasons : {
              code      = reason.code
              message   = reason.message
              more_info = reason.more_info
            }
          ], [])
          tunnels = try([
            for tunnel in conn.tunnels : {
              resource_type = tunnel.resource_type
              address       = tunnel.address
            }
          ])
        }
      ], [])
    }
  }
}
