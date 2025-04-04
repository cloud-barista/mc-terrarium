# outputs.tf
output "ibm_testbed_info" {
  description = "IBM, resource details"
  value       = length(module.ibm) > 0 ? module.ibm.testbed_info : {}
}

output "ibm_testbed_ssh_info" {
  description = "IBM, SSH connection information"
  sensitive   = true
  value = {
    ibm = try(module.ibm.ssh_info, null)
  }
}
