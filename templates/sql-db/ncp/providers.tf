terraform {

  # Required Tofu version
  required_version = ">=1.8.3"

  required_providers {
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
      version = "3.2.1"
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

# Read NCP credentials from OpenBao
data "vault_kv_secret_v2" "ncp" {
  mount = "secret"
  name  = "csp/ncp"
}

provider "ncloud" {
  access_key  = data.vault_kv_secret_v2.ncp.data["NCLOUD_ACCESS_KEY"]
  secret_key  = data.vault_kv_secret_v2.ncp.data["NCLOUD_SECRET_KEY"]
  region      = upper(var.csp_region) # Set the desired region (e.g., "KR", "JP", etc.)
  support_vpc = true                  # Enable VPC support
}

