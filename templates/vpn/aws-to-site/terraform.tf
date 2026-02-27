# providers.tf
terraform {
  required_version = ">=1.8.3"

  required_providers {
    # AWS provider
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
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
    # Google provider
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
      version = "~>5.21"
    }
    # Alibaba Cloud provider
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~>1.243.0"
    }
    # Tencent Cloud provider
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~>1.81.173"
    }
    # IBM Cloud provider
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "~>1.76.0"
    }
    # Vault provider for OpenBao credential management
    vault = {
      source  = "hashicorp/vault"
      version = "~>4.0"
    }
  }
}

# Vault provider reads VAULT_ADDR and VAULT_TOKEN from environment
provider "vault" {}
