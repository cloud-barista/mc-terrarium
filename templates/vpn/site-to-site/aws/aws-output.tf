output "aws_vpn_info" {
  description = "AWS, VPN resource details"
  value = {
    aws = merge(
      // AWS VPN Gateway details
      {
        vpn_gateway = {
          resource_type = "aws_vpn_gateway"
          name          = try(aws_vpn_gateway.vpn_gw.tags.Name, "")
          id            = try(aws_vpn_gateway.vpn_gw.id, "")
          vpc_id        = try(aws_vpn_gateway.vpn_gw.vpc_id, "")
        }
      },
      // AWS VPN connection details
      try(module.conn_aws_azure.aws_vpn_conn_info, {})
      // To be added, AWS VPN connection details with other providers
      // e.g., Alibaba, GCP, etc.
    )
  }
}
