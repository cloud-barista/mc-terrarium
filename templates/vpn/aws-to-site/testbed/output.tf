# outputs.tf
output "network_details" {
  description = "Network resource details"
  value = {
    aws = {
      vpc_id      = aws_vpc.main.id
      vpc_cidr    = aws_vpc.main.cidr_block
      subnet_id   = aws_subnet.main.id
      subnet_cidr = aws_subnet.main.cidr_block
    }
    gcp = {
      vpc_name    = google_compute_network.main.name
      subnet_name = google_compute_subnetwork.main.name
      subnet_cidr = google_compute_subnetwork.main.ip_cidr_range
      project_id  = jsondecode(file("credential-gcp.json")).project_id
    }
    azure = {
      region               = azurerm_resource_group.main.location
      resource_group_name  = azurerm_resource_group.main.name
      virtual_network_name = azurerm_virtual_network.main.name
      gateway_subnet_cidr  = "10.2.2.0/24" # Reserved for VPN Gateway
    }
    alibaba = {
      vpc_id       = alicloud_vpc.main.id
      vpc_cidr     = alicloud_vpc.main.cidr_block
      vswitch_id   = alicloud_vswitch.main.id
      vswitch_cidr = alicloud_vswitch.main.cidr_block
    }
  }
}

output "ssh_info" {
  description = "SSH connection information"
  sensitive   = true
  value = {
    private_key = tls_private_key.ssh.private_key_pem
    aws = {
      public_ip  = aws_instance.main.public_ip
      private_ip = aws_instance.main.private_ip
      user       = "ubuntu"
      command    = "ssh -i private_key.pem ubuntu@${aws_instance.main.public_ip}"
    }
    gcp = {
      public_ip  = google_compute_instance.main.network_interface[0].access_config[0].nat_ip
      private_ip = google_compute_instance.main.network_interface[0].network_ip
      user       = "ubuntu"
      command    = "ssh -i private_key.pem ubuntu@${google_compute_instance.main.network_interface[0].access_config[0].nat_ip}"
    }
    azure = {
      public_ip  = azurerm_public_ip.main.ip_address != "" ? azurerm_public_ip.main.ip_address : azurerm_public_ip.main.fqdn
      private_ip = azurerm_network_interface.main.private_ip_address
      user       = "ubuntu"
      command    = "ssh -i private_key.pem ubuntu@${azurerm_public_ip.main.ip_address != "" ? azurerm_public_ip.main.ip_address : azurerm_public_ip.main.fqdn}"
    }
    alibaba = {
      public_ip  = alicloud_instance.main.public_ip
      private_ip = alicloud_instance.main.private_ip
      user       = "ubuntu"
      command    = "ssh -i private_key.pem ubuntu@${alicloud_instance.main.public_ip}"
    }
  }
}
