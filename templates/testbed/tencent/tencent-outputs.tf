# outputs.tf
output "tencent_testbed_info" {
  description = "Tencent, resource details"
  value       = length(module.tencent) > 0 ? module.tencent.testbed_info : {}
}

output "tencent_testbed_ssh_info" {
  description = "Tencent, SSH connection information"
  sensitive   = true
  value       = try(module.tencent.ssh_info, {})
}
