# outputs.tf
output "ibm_vpn_info" {
  description = "IBM, VPN resource details"
  value       = try(module.ibm.vpn_info, {})
}
