# # outputs.tf
# output "aws_vpn_conn_info" {
#   description = "AWS, VPN resource details"
#   value       = try(module.conn_aws_azure.aws_vpn_conn_info, {})
# }

# output "azure_vpn_conn_info" {
#   description = "Azure, VPN resource details"
#   value       = try(module.conn_aws_azure.azure_vpn_conn_info, {})
# }
