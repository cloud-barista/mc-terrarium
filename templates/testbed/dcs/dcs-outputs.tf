output "dcs_testbed_info" {
  description = "DCS, resource details"
  value       = module.dcs.info
}

output "dcs_testbed_ssh_info" {
  description = "DCS, SSH connection information"
  value = {
    command = "ssh -i private_key.pem ubuntu@${module.dcs.info.public_ip}"
  }
}
