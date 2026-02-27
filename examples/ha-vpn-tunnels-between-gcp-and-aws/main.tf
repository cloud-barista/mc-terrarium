# Define the required version of OpenTofu and the providers that will be used in the project
terraform {
  # Required OpenTofu version
  required_version = ">=1.8.3"

  required_providers {
    # AWS provider is specified with its source and version
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }

    # Google provider is specified with its source and version
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
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

# ── Read AWS credentials from OpenBao ─────────────────────────────
data "vault_kv_secret_v2" "aws" {
  mount = "secret"
  name  = "csp/aws"
}

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
}

# ── AWS Provider using OpenBao credentials ────────────────────────
provider "aws" {
  region     = "ap-northeast-2"
  access_key = data.vault_kv_secret_v2.aws.data["AWS_ACCESS_KEY_ID"]
  secret_key = data.vault_kv_secret_v2.aws.data["AWS_SECRET_ACCESS_KEY"]
}

# ── Google Provider using OpenBao credentials ────────────────────
provider "google" {
  credentials = local.my_gcp_credential

  project = local.my_gcp_project_id
  region  = "asia-northeast3"
  zone    = "asia-northeast3-c"
}
