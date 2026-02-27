# Define the required version of OpenTofu and the providers that will be used in the project
terraform {
  # Required OpenTofu version
  required_version = ">=1.8.3"

  required_providers {
    # Google provider is specified with its source and version
    google = {
      source  = "hashicorp/google"
      version = "~>5.21"
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

locals {
  # Reconstruct GCP service account JSON from OpenBao secrets
  my_gcp_credential = jsonencode({
    type           = "service_account"
    project_id     = data.vault_kv_secret_v2.gcp.data["project_id"]
    private_key_id = data.vault_kv_secret_v2.gcp.data["private_key_id"]
    private_key    = replace(data.vault_kv_secret_v2.gcp.data["private_key"], "\\n", "\n")
    client_email   = data.vault_kv_secret_v2.gcp.data["client_email"]
    client_id      = data.vault_kv_secret_v2.gcp.data["client_id"]
    auth_uri       = "https://accounts.google.com/o/oauth2/auth"
    token_uri      = "https://oauth2.googleapis.com/token"
  })
  my_gcp_project_id = data.vault_kv_secret_v2.gcp.data["project_id"]

  # Define the region as a local variable to reuse it across resources
  my_region = "asia-northeast3"
}

# NOTE: Storage location scope varies:
# * Regional: us-central1, europe-west1, asia-east1.
# * Dual-region: nam4, eur4
# * Multi-region: US, EU, ASIA.

# ── Google Provider using OpenBao credentials ────────────────────
provider "google" {
  credentials = local.my_gcp_credential

  project = local.my_gcp_project_id
  region  = local.my_region
  zone    = "${local.my_region}-c"
}

resource "google_storage_bucket" "tofu_example_bucket" {
  name                        = "tofu-example-bucket"
  location                    = local.my_region
  force_destroy               = true
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}
