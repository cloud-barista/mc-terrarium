data "azurerm_resource_group" "injected_rg" {
  name = var.azure-resource-group-name
}

# Generate SSH key pair
resource "random_pet" "ssh_key_name" {
  prefix    = "ssh"
  separator = ""
}

resource "azapi_resource" "azure_ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name.id
  location  = var.azure-region
  parent_id = data.azurerm_resource_group.injected_rg.id
}

resource "azapi_resource_action" "azure_ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.azure_ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

output "key-data" {
  value = jsondecode(azapi_resource_action.azure_ssh_public_key_gen.output).publicKey
}
