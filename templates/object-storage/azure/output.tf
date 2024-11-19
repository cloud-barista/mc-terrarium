output "object_storage_info" {
  description = "Information about Azure Blob storage"
  value = {
    terrarium = {
      id = var.terrarium_id # "terrarium-01"
    }
    object_storage_detail = {
      # Basic Information
      storage_name = azurerm_storage_account.object_storage_account.name     # "terrarium01"
      location     = azurerm_storage_account.object_storage_account.location # "koreacentral"
      tags         = azurerm_storage_account.object_storage_account.tags     # {}

      # Access Configuration
      public_access_enabled = azurerm_storage_account.object_storage_account.public_network_access_enabled # true
      https_only            = azurerm_storage_account.object_storage_account.enable_https_traffic_only     # true
      primary_endpoint      = azurerm_storage_account.object_storage_account.primary_blob_endpoint         # "https://terrarium01.blob.core.windows.net/"

      provider_specific_detail = {
        provider             = "azure"                                                                 # "azure"
        storage_account_name = azurerm_storage_account.object_storage_account.name                     # "terrarium01"
        resource_group       = azurerm_storage_account.object_storage_account.resource_group_name      # "koreacentral"
        account_tier         = azurerm_storage_account.object_storage_account.account_tier             # "Standard"
        replication_type     = azurerm_storage_account.object_storage_account.account_replication_type # "LRS"
        access_tier          = azurerm_storage_account.object_storage_account.access_tier              # "Hot"

        endpoints = {
          blob      = azurerm_storage_account.object_storage_account.primary_blob_endpoint # "https://terrarium01.blob.core.windows.net/"
          blob_host = azurerm_storage_account.object_storage_account.primary_blob_host     # "terrarium01.blob.core.windows.net"
          dfs       = azurerm_storage_account.object_storage_account.primary_dfs_endpoint  # "https://terrarium01.dfs.core.windows.net/"
          web       = azurerm_storage_account.object_storage_account.primary_web_endpoint  # "https://terrarium01.z12.web.core.windows.net/"
        }

        network_rules = {
          default_action = azurerm_storage_account.object_storage_account.network_rules[0].default_action # "Allow"
          bypass         = azurerm_storage_account.object_storage_account.network_rules[0].bypass         # ["AzureServices"]
        }
      }
    }
  }
}

# # For design
# output "azurerm_storage_account_all" {
#   description = "All information"
#   value       = azurerm_storage_account.object_storage_account
#   sensitive   = true
# }

# output "azurerm_storage_container_all" {
#   description = "All information"
#   value       = azurerm_storage_container.object_storage
#   sensitive   = true
# }
