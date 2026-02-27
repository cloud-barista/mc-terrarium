# Define the required version of OpenTofu and the providers that will be used in the project
terraform {
  # Required Tofu version
  required_version = ">=1.8.3"

  required_providers {
    # Google provider is specified with its source and version
    google = {
      source  = "hashicorp/google"
      version = "~>5.21"
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

# Read GCP credentials from OpenBao
data "vault_kv_secret_v2" "gcp" {
  mount = "secret"
  name  = "csp/gcp"
}

# Reconstruct GCP credential JSON from OpenBao KV data
locals {
  my_gcp_credential = jsonencode({
    type                        = "service_account"
    project_id                  = data.vault_kv_secret_v2.gcp.data["project_id"]
    private_key_id              = data.vault_kv_secret_v2.gcp.data["private_key_id"]
    private_key                 = replace(data.vault_kv_secret_v2.gcp.data["private_key"], "\\n", "\n")
    client_email                = data.vault_kv_secret_v2.gcp.data["client_email"]
    client_id                   = data.vault_kv_secret_v2.gcp.data["client_id"]
    auth_uri                    = "https://accounts.google.com/o/oauth2/auth"
    token_uri                   = "https://oauth2.googleapis.com/token"
    auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs"
    client_x509_cert_url        = "https://www.googleapis.com/robot/v1/metadata/x509/${urlencode(data.vault_kv_secret_v2.gcp.data["client_email"])}"
  })
  my_gcp_project_id = data.vault_kv_secret_v2.gcp.data["project_id"]
}

# Provider block for Google specifies the configuration for the provider
provider "google" {
  credentials = local.my_gcp_credential

  project = local.my_gcp_project_id
  region  = var.csp_region
  # zone    = "asia-northeast3-c"
}

