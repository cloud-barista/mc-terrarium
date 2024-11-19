
# # Generate random string
# resource "random_string" "suffix" {
#   length  = 6
#   special = false
#   upper   = false # Set to false to avoid using uppercase letters
# }

# Create the Storage Account
resource "azurerm_storage_account" "object_storage_account" {
  name                     = var.terrarium_id # Globally unique name, only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
  resource_group_name      = var.csp_resource_group
  location                 = var.csp_region
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally Redundant Storage

}

# Create a Blob container
resource "azurerm_storage_container" "object_storage" {
  name                  = "${var.terrarium_id}-container"
  storage_account_name  = azurerm_storage_account.object_storage_account.name
  container_access_type = "private" # Private, Blob, or Container
}
