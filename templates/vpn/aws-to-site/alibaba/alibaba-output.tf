# outputs.tf
output "alibaba_vpn_info" {
  description = "Alibaba, VPN resource details"
  value       = try(module.alibaba.vpn_info, {})
}
