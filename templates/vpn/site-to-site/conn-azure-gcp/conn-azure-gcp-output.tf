# outputs.tf
output "azure_vpn_conn_info" {
  description = "Azure, VPN resource details"
  value       = try(module.conn_azure_gcp.azure_vpn_conn_info, {})
}

output "gcp_vpn_conn_info" {
  description = "GCP, VPN resource details"
  value       = try(module.conn_azure_gcp.gcp_vpn_conn_info, {})
}
