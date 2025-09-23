output "ssh_info" {
  description = "SSH connection information"
  sensitive   = true
  value = {
    private_key = tls_private_key.ssh.private_key_pem
    vms = {
      for vm_key, vm_instance in aws_instance.vms : vm_key => {
        public_ip  = vm_instance.public_ip
        private_ip = vm_instance.private_ip
        user       = "ubuntu"
        command    = "ssh -i private_key.pem ubuntu@${vm_instance.public_ip}"
      }
    }
  }
}

output "testbed_info" {
  description = "Testbed infrastructure information"
  value = {
    terrarium_id = var.terrarium_id
    vpc_id       = aws_vpc.main.id
    vpc_cidr     = aws_vpc.main.cidr_block
    subnet_id    = aws_subnet.main.id
    subnet_cidr  = aws_subnet.main.cidr_block
    vm_count     = length(var.vm_configurations)
  }
}

output "vm_details" {
  description = "Detailed VM information with service roles"
  value = {
    for vm_key, vm_instance in aws_instance.vms : vm_key => {
      instance_id    = vm_instance.id
      instance_type  = vm_instance.instance_type
      public_ip      = vm_instance.public_ip
      private_ip     = vm_instance.private_ip
      vcpu           = var.vm_configurations[vm_key].vcpu
      memory_gb      = var.vm_configurations[vm_key].memory_gb
      service_role   = var.vm_configurations[vm_key].service_role
      security_group = aws_security_group.main.id
    }
  }
}

output "security_group_info" {
  description = "Security group information"
  value = {
    security_group_id      = aws_security_group.main.id
    security_group_name    = aws_security_group.main.name
    vpc_cidr               = aws_vpc.main.cidr_block
    additional_cidr_blocks = var.allowed_cidr_blocks
    all_allowed_cidrs      = concat([aws_vpc.main.cidr_block], var.allowed_cidr_blocks)
    description            = "Single security group used by all VMs with UFW for host-level firewall rules"
  }
}

output "vm_summary" {
  description = "Summary of VM configurations with service roles"
  value = {
    for vm_key, vm_config in var.vm_configurations : vm_key => {
      specs = {
        vcpu          = vm_config.vcpu
        memory_gb     = vm_config.memory_gb
        instance_type = vm_config.instance_type
        service_role  = vm_config.service_role
      }
      public_ip      = aws_instance.vms[vm_key].public_ip
      private_ip     = aws_instance.vms[vm_key].private_ip
      security_group = aws_security_group.main.id
    }
  }
}

output "service_roles" {
  description = "Service roles assigned to each VM"
  value = {
    for vm_key, vm_config in var.vm_configurations : vm_key => vm_config.service_role
  }
}
