# Generate SSH key pair
resource "random_pet" "my-azure-ssh-key-name" {
  prefix    = "ssh"
  separator = ""
}

resource "azapi_resource" "my-azure-ssh-public-key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.my-azure-ssh-key-name.id
  location  = azurerm_resource_group.my-azure-resource-group.location
  parent_id = azurerm_resource_group.my-azure-resource-group.id
}

resource "azapi_resource_action" "my-azure-ssh-public-key-gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.my-azure-ssh-public-key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

output "key-data" {
  value = azapi_resource_action.my-azure-ssh-public-key-gen.output.publicKey
}
