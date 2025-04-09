# outputs.tf
output "tencent_vpn_info" {
  description = "Tencent, VPN resource details"
  value       = try(module.tencent.vpn_info, {})
}
