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

output "source_nodes_inventory" {
  description = "Source Nodes inventory (excludes general / cloud-migrator) for CM-Honeybee / CM-Beetle / CM-Butterfly registration"
  value = {
    for vm_key in local.source_vm_keys : vm_key => {
      hostname      = vm_key
      private_ip    = module.migration_testbed.vm_summary[vm_key].private_ip
      public_ip     = module.migration_testbed.vm_summary[vm_key].public_ip
      ssh_port      = 22
      ssh_user      = "ubuntu"
      instance_type = var.vm_configurations[vm_key].instance_type
      service_role  = var.vm_configurations[vm_key].service_role
      description   = coalesce(var.vm_configurations[vm_key].description, "${var.vm_configurations[vm_key].service_role} node")
    }
  }
}

output "generated_import_files" {
  description = "Auto-generated PEM, CSV (cm-butterfly/cm-beetle), JSON, and YAML (cm-beetle UX Lab) bulk import files"
  value = {
    private_key_pem                 = local_file.private_key_pem.filename
    private_key_oneline_pem         = local_file.private_key_oneline_pem.filename
    source_connections_private_csv  = local_file.source_connections_private_csv.filename
    source_connections_public_csv   = local_file.source_connections_public_csv.filename
    source_connections_private_json = local_file.source_connections_private_json.filename
    source_connections_public_json  = local_file.source_connections_public_json.filename
    source_connections_private_yaml = local_file.source_connections_private_yaml.filename
    source_connections_public_yaml  = local_file.source_connections_public_yaml.filename
  }
}

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    terrarium_id    = var.terrarium_id
    region          = var.aws_region
    vpc_cidr        = var.vpc_cidr
    vm_count        = length(var.vm_configurations)
    source_vm_count = length(local.source_vm_keys)
    service_roles   = [for vm_key, vm_config in var.vm_configurations : vm_config.service_role]
    total_vcpu      = sum([for vm_key, vm_config in var.vm_configurations : vm_config.vcpu])
    total_memory_gb = sum([for vm_key, vm_config in var.vm_configurations : vm_config.memory_gb])
    total_disk_gb   = sum([for vm_key, vm_config in var.vm_configurations : coalesce(vm_config.root_disk_gb, 50)])
  }
}