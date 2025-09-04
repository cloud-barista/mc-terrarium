# Alibaba VPN Gateway outputs
output "alibaba_vpn_gateway_id" {
  description = "ID of the Alibaba VPN Gateway"
  value       = alicloud_vpn_gateway.main.id
}

output "alibaba_vpn_gateway_internet_ip" {
  description = "Internet IP of the Alibaba VPN Gateway"
  value       = alicloud_vpn_gateway.main.internet_ip
}

output "alibaba_vpc_id" {
  description = "Alibaba VPC ID"
  value       = var.vpn_config.alibaba.vpc_id
}

output "alibaba_region" {
  description = "Alibaba region"
  value       = var.vpn_config.alibaba.region
}

output "alibaba_bgp_asn" {
  description = "Alibaba BGP ASN"
  value       = var.vpn_config.alibaba.bgp_asn
}
