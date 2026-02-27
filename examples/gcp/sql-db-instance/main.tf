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
}

# ── Google Provider using OpenBao credentials ────────────────────
provider "google" {
  credentials = local.my_gcp_credential

  project = local.my_gcp_project_id
  region  = "asia-northeast3"
  zone    = "asia-northeast3-c"
}


# Create SQL MySQL instance
resource "google_sql_database_instance" "my_sql_instance" {
  name             = "my-sql-instance"
  database_version = "MYSQL_8_0" # Specify the MySQL version you need
  # region           = "us-central1"

  settings {
    tier = "db-f1-micro" # Set the instance type
  }

  deletion_protection = false # Disable deletion protection
}

# Create database
resource "google_sql_database" "my_database" {
  name     = "mydatabase"
  instance = google_sql_database_instance.my_sql_instance.name
}

# Create user (optional)
resource "google_sql_user" "my_user" {
  name     = "myuser"
  instance = google_sql_database_instance.my_sql_instance.name
  password = "my-secret-password" # Set a strong password
}
