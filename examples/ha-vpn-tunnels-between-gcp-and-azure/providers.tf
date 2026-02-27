# Define the required version of OpenTofu and the providers that will be used in the project
terraform {
  # Specify the required OpenTofu version
  required_version = ">=1.8.3"

  # Specify the required providers and their versions
  required_providers {
    # Google provider
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
      version = "~>5.21"
    }

    # The Azure Provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.97.0"
    }
    # The AzAPI provider
    azapi = {
      source  = "azure/azapi"
      version = "~>1.12"
    }

    # Vault provider for OpenBao credential access
    vault = {
      source  = "registry.opentofu.org/hashicorp/vault"
      version = "~>4.0"
    }
  }
}

# ── OpenBao Provider (Vault-compatible) ───────────────────────────
# Reads VAULT_ADDR and VAULT_TOKEN from environment variables.
provider "vault" {}

# ── Read GCP credentials from OpenBao ─────────────────────────────
data "vault_kv_secret_v2" "gcp" {
  mount = "secret"
  name  = "csp/gcp"
}

# ── Read Azure credentials from OpenBao ───────────────────────────
data "vault_kv_secret_v2" "azure" {
  mount = "secret"
  name  = "csp/azure"
}

locals {
  # Reconstruct GCP service account JSON from OpenBao secrets
  my-gcp-credential = jsonencode({
    type           = "service_account"
    project_id     = data.vault_kv_secret_v2.gcp.data["project_id"]
    private_key_id = data.vault_kv_secret_v2.gcp.data["private_key_id"]
    private_key    = replace(data.vault_kv_secret_v2.gcp.data["private_key"], "\\n", "\n")
    client_email   = data.vault_kv_secret_v2.gcp.data["client_email"]
    client_id      = data.vault_kv_secret_v2.gcp.data["client_id"]
    auth_uri       = "https://accounts.google.com/o/oauth2/auth"
    token_uri      = "https://oauth2.googleapis.com/token"
  })
  my-gcp-project-id = data.vault_kv_secret_v2.gcp.data["project_id"]
}

# ── Google Provider using OpenBao credentials ────────────────────
provider "google" {
  credentials = local.my-gcp-credential

  project = local.my-gcp-project-id
  region  = var.my-gcp-region
}

# The "random" provider allows the use of randomness within OpenTofu configurations.
# It is used to select a zone in a region randomly.
provider "random" {
  # Optional configuration for the random provider
}

# [NOTE]
# Ref.) Azure Provider: Authenticating using a Service Principal with a Client Secret
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret

# ── Azure Provider using OpenBao credentials ─────────────────────
provider "azurerm" {
  # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  skip_provider_registration = true
  features {}

  client_id       = data.vault_kv_secret_v2.azure.data["ARM_CLIENT_ID"]
  client_secret   = data.vault_kv_secret_v2.azure.data["ARM_CLIENT_SECRET"]
  tenant_id       = data.vault_kv_secret_v2.azure.data["ARM_TENANT_ID"]
  subscription_id = data.vault_kv_secret_v2.azure.data["ARM_SUBSCRIPTION_ID"]
}

# Create a resource group
resource "azurerm_resource_group" "my-azure-resource-group" {
  name = "my-azure-resource-group-name"
  # Default: "koreacentral"
  location = var.my-azure-region
}
