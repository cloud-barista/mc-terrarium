# outputs.tf
output "azure_vpn_info" {
  description = "Azure, VPN resource details"
  value       = try(module.azure.vpn_info, {})
}

