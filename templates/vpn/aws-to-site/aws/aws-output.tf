output "aws_vpn_info" {
  description = "AWS, VPN resource details"
  value = {
    aws = {
      vpn_gateway = {
        resource_type = "aws_vpn_gateway"
        name          = aws_vpn_gateway.vpn_gw.tags.Name
        id            = aws_vpn_gateway.vpn_gw.id
        vpc_id        = aws_vpn_gateway.vpn_gw.vpc_id
      }
    }
  }
}
