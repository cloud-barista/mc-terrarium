terraform {

  # Required OpenTofu version
  required_version = ">=1.8.3"

  required_providers {
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
      version = "3.2.1"
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

# ── Read NCP credentials from OpenBao ─────────────────────────────
data "vault_kv_secret_v2" "ncp" {
  mount = "secret"
  name  = "csp/ncp"
}

# ── NCP Provider using OpenBao credentials ───────────────────────
provider "ncloud" {
  access_key  = data.vault_kv_secret_v2.ncp.data["NCLOUD_ACCESS_KEY"]
  secret_key  = data.vault_kv_secret_v2.ncp.data["NCLOUD_SECRET_KEY"]
  region      = "KR" # Set the desired region (e.g., "KR", "JP", etc.)
  support_vpc = true # Enable VPC support
}

# Create object storage bucket
resource "ncloud_objectstorage_bucket" "tofu_bucket" {
  bucket_name = "tofu-bucket"
}
