// AWS
output "aws_vpc_id" {
  value = aws_vpc.test_vpc.id
}

output "aws_subnet_0_id" {
  value = aws_subnet.test_subnet_0.id
}

output "aws_subnet_1_id" {
  value = aws_subnet.test_subnet_1.id
}

output "aws_instance_private_ip" {
  value = aws_instance.test_ec2_instance.private_ip
}

// Azure
output "azure_virtual_network_name" {
  value = azurerm_virtual_network.test_vnet.name
}

output "azure_subnet_0_name" {
  value = azurerm_subnet.test_subnet_0.name
}

output "azure_subnet_1_name" {
  value = azurerm_subnet.test_subnet_1.name
}

output "azure_subnet_0_address_prefix" {
  value = azurerm_subnet.test_subnet_0.address_prefixes
}

output "azure_subnet_1_address_prefix" {
  value = azurerm_subnet.test_subnet_1.address_prefixes
}

output "azure_virtual_machine_private_ip" {
  value = azurerm_linux_virtual_machine.test_vm_1.private_ip_address
}

output "key-data" {
  value = azapi_resource_action.test_azure_ssh_public_key_gen.output.publicKey
}

// GCP
output "gcp_vpc_network_name" {
  value = google_compute_network.test_vpc_network.name
}

output "gcp_subnetwork_0_name" {
  value = google_compute_subnetwork.test_subnetwork_0.name
}

output "gcp_subnetwork_1_name" {
  value = google_compute_subnetwork.test_subnetwork_1.name
}

output "gcp_vm_instance_private_ip" {
  value = google_compute_instance.test_vm_instance.network_interface.0.network_ip
}
