terraform {
  required_providers {
    # Azure provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.97.0"
    }
    # AzAPI provider
    azapi = {
      source  = "azure/azapi"
      version = "~>1.12"
    }
    # Alibaba Cloud provider
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~>1.243.0"
    }
  }
}
