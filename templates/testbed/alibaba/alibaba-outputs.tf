# outputs.tf
output "alibaba_testbed_info" {
  description = "Alibaba, resource details"
  value       = length(module.alibaba) > 0 ? module.alibaba.testbed_info : {}
}

output "alibaba_testbed_ssh_info" {
  description = "Alibaba, SSH connection information"
  sensitive   = true
  value       = try(module.alibaba.ssh_info, {})
}
