# Define the required version of OpenTofu and the providers that will be used in the project
terraform {
  # Required Tofu version
  required_version = ">=1.8.3"

  required_providers {
    # Azure provider is specified with its source and version
    azapi = {
      source  = "azure/azapi"
      version = "~>1.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.97.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
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

# Read Azure credentials from OpenBao
data "vault_kv_secret_v2" "azure" {
  mount = "secret"
  name  = "csp/azure"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  skip_provider_registration = true
  features {}

  client_id       = data.vault_kv_secret_v2.azure.data["ARM_CLIENT_ID"]
  client_secret   = data.vault_kv_secret_v2.azure.data["ARM_CLIENT_SECRET"]
  tenant_id       = data.vault_kv_secret_v2.azure.data["ARM_TENANT_ID"]
  subscription_id = data.vault_kv_secret_v2.azure.data["ARM_SUBSCRIPTION_ID"]
}
