# outputs.tf
output "alibaba_vpn_conn_info" {
  description = "Alibaba, VPN resource details"
  value       = try(module.conn_alibaba_azure.alibaba_vpn_conn_info, {})
}

output "azure_vpn_conn_info" {
  description = "Azure, VPN resource details"
  value       = try(module.conn_alibaba_azure.azure_vpn_conn_info, {})
}
