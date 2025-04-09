# outputs.tf
output "gcp_vpn_info" {
  description = "GCP, VPN resource details"
  value       = try(module.gcp.vpn_info, {})
}
