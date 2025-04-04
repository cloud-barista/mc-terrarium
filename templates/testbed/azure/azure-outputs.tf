# outputs.tf
output "azure_testbed_info" {
  description = "Azure, resource details"
  value       = length(module.azure) > 0 ? module.azure.testbed_info : {}
}

output "azure_testbed_ssh_info" {
  description = "Azure, SSH connection information"
  sensitive   = true
  value = {
    azure = try(module.azure.ssh_info, null)
  }
}
