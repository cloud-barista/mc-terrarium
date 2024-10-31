output "storage_account_info" {
  description = "Information about the Azure Storage Account."
  value = {
    account_name     = azurerm_storage_account.example.name
    account_tier     = azurerm_storage_account.example.account_tier
    primary_region   = azurerm_storage_account.example.location
    primary_endpoint = azurerm_storage_account.example.primary_blob_endpoint
  }
}

output "blob_container_info" {
  description = "Information about the Azure Blob Container."
  value = {
    container_name = azurerm_storage_container.example.name
    access_type    = azurerm_storage_container.example.container_access_type
  }
}
