output "storage_account_info" {
  description = "Information about the Azure Storage Account for Azure Files."
  value = {
    account_name     = azurerm_storage_account.example.name
    primary_location = azurerm_storage_account.example.primary_location
    primary_endpoint = azurerm_storage_account.example.primary_file_endpoint
  }
}

output "file_share_info" {
  description = "Information about the Azure File Share."
  value = {
    share_name       = azurerm_storage_share.example.name
    storage_quota_gb = azurerm_storage_share.example.quota
  }
}
