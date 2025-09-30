# DCS (DevStack Cloud Service) Infrastructure Outputs

# SSH Key Information
output "ssh_private_key" {
  description = "Generated SSH private key"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "ssh_public_key" {
  description = "Generated SSH public key"
  value       = tls_private_key.ssh.public_key_openssh
}

# Primary Instance Information
output "instance_info" {
  description = "Primary instance information"
  value = {
    name        = openstack_compute_instance_v2.main.name
    private_ip  = openstack_compute_instance_v2.main.access_ip_v4
    floating_ip = openstack_networking_floatingip_v2.main.address
  }
}

# Secondary Instance Information
output "secondary_instance_info" {
  description = "Secondary instance information"
  value = {
    name        = openstack_compute_instance_v2.secondary.name
    private_ip  = openstack_compute_instance_v2.secondary.access_ip_v4
    floating_ip = openstack_networking_floatingip_v2.secondary.address
  }
}

# Quick Access Commands
output "ssh_commands" {
  description = "SSH commands for accessing instances"
  value = {
    primary       = "# Save private key first: tofu output -raw ssh_private_key > dcs-key.pem && chmod 600 dcs-key.pem"
    primary_ssh   = "ssh -i dcs-key.pem ubuntu@${openstack_networking_floatingip_v2.main.address}"
    secondary_ssh = "ssh -i dcs-key.pem ubuntu@${openstack_networking_floatingip_v2.secondary.address}"
  }
}

# Web Access URLs
output "web_urls" {
  description = "Web access URLs"
  value = {
    primary   = "http://${openstack_networking_floatingip_v2.main.address}"
    secondary = "http://${openstack_networking_floatingip_v2.secondary.address}"
  }
}
