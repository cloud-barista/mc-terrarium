# AWS Migration Testbed - Root Outputs

# Forward all module outputs
output "ssh_info" {
  description = "SSH connection information"
  value       = module.migration_testbed.ssh_info
  sensitive   = true
}

output "testbed_info" {
  description = "Testbed infrastructure information"
  value       = module.migration_testbed.testbed_info
}

output "vm_details" {
  description = "Detailed VM information with service roles"
  value       = module.migration_testbed.vm_details
}

output "vm_summary" {
  description = "Summary of VM configurations with service roles"
  value       = module.migration_testbed.vm_summary
}

output "security_group_info" {
  description = "Security group information"
  value       = module.migration_testbed.security_group_info
}

output "service_roles" {
  description = "Service roles assigned to each VM"
  value       = module.migration_testbed.service_roles
}

output "network_info" {
  description = "Network infrastructure information"
  value       = module.migration_testbed.network_info
}

output "key_pair_info" {
  description = "SSH key pair information"
  value       = module.migration_testbed.key_pair_info
}

# Additional convenience outputs
output "quick_ssh_commands" {
  description = "Quick SSH commands for each VM"
  value = {
    for vm_key, vm_info in module.migration_testbed.ssh_info.vms : 
    vm_key => vm_info.command
  }
  sensitive = true
}

output "vm_public_ips" {
  description = "Public IP addresses of all VMs"
  value = {
    for vm_key, vm_info in module.migration_testbed.vm_summary : 
    vm_key => vm_info.public_ip
  }
}

output "vm_private_ips" {
  description = "Private IP addresses of all VMs"
  value = {
    for vm_key, vm_info in module.migration_testbed.vm_summary : 
    vm_key => vm_info.private_ip
  }
}

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    terrarium_id      = var.terrarium_id
    region            = var.aws_region
    vpc_cidr          = var.vpc_cidr
    vm_count          = length(var.vm_configurations)
    service_roles     = [for vm_key, vm_config in var.vm_configurations : vm_config.service_role]
    total_vcpu        = sum([for vm_key, vm_config in var.vm_configurations : vm_config.vcpu])
    total_memory_gb   = sum([for vm_key, vm_config in var.vm_configurations : vm_config.memory_gb])
  }
}