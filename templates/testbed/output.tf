# outputs.tf
output "testbed_info" {
  description = "Testbed resource details"
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
      vpc_id         = alicloud_vpc.main.id
      vpc_cidr       = alicloud_vpc.main.cidr_block
      vswitch_1_id   = alicloud_vswitch.main.id
      vswitch_1_cidr = alicloud_vswitch.main.cidr_block
      vswitch_2_id   = alicloud_vswitch.secondary.id
      vswitch_2_cidr = alicloud_vswitch.secondary.cidr_block
    }
    ibm = {
      vpc_id      = ibm_is_vpc.main.id
      vpc_crn     = ibm_is_vpc.main.crn # The VPC CRN (Cloud Resource Name) to provide DNS server addresses for this VPC
      subnet_id   = ibm_is_subnet.main.id
      subnet_cidr = ibm_is_subnet.main.ipv4_cidr_block
    }
  }
}

data "azurerm_public_ip" "main" {
  name                = azurerm_public_ip.main.name
  resource_group_name = azurerm_resource_group.main.name
  depends_on          = [azurerm_linux_virtual_machine.main]
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
      public_ip  = data.azurerm_public_ip.main.ip_address # azurerm_public_ip.main.ip_address != "" ? data.azurerm_public_ip.main.ip_address : azurerm_public_ip.main.fqdn
      private_ip = azurerm_network_interface.main.private_ip_address
      user       = "ubuntu"
      command    = "ssh -i private_key.pem ubuntu@${data.azurerm_public_ip.main.ip_address}" # "ssh -i private_key.pem ubuntu@${azurerm_public_ip.main.ip_address != "" ?  : azurerm_public_ip.main.fqdn}"
    }
    alibaba = {
      public_ip  = alicloud_instance.main.public_ip
      private_ip = alicloud_instance.main.private_ip
      user       = "ubuntu"
      command    = "ssh -i private_key.pem ubuntu@${alicloud_instance.main.public_ip}"
    }
    ibm = {
      public_ip  = ibm_is_floating_ip.main.address
      private_ip = ibm_is_instance.main.primary_network_interface[0].primary_ip[0].address
      user       = "ubuntu"
      command    = "ssh -i private_key.pem ubuntu@${ibm_is_floating_ip.main.address}"
    }
  }
  depends_on = [azurerm_linux_virtual_machine.main, data.azurerm_public_ip.main]
}
