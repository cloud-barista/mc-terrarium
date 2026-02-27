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

# ── Google Provider using OpenBao credentials ────────────────────
provider "google" {
  credentials = local.my_gcp_credential

  project = local.my_gcp_project_id
  region  = local.my_region
  zone    = "${local.my_region}-c"
}


# Enable Firestore API (Firestore requires this API to be enabled)
resource "google_project_service" "tofu_example_firestore" {
  # project = "<YOUR_PROJECT_ID>"
  service = "firestore.googleapis.com"
}

# "(default)" is required to create a Firestore database
resource "google_firestore_database" "tofu_example_firestore_db" {
  # count = length([for db in google_firestore_database.tofu_example_firestore_db : db if db.name == "(default)"]) == 0 ? 1 : 0
  name = "tofu-example-db" # Firestore database name.  default is "(default)"
  # project    = local.my_gcp_project_id
  location_id = local.my_region
  type        = "FIRESTORE_NATIVE"
}

# Firestore index creation (optional)
resource "google_firestore_index" "tofu_example_index" {
  project    = local.my_gcp_project_id
  collection = "tofu-example-collection-name" # Collection for which the index is created
  fields {
    field_path = "field_1"
    order      = "ASCENDING"
  }
  fields {
    field_path = "field_2"
    order      = "DESCENDING"
  }

  # Ensure the index is created only after the database is available
  depends_on = [google_firestore_database.tofu_example_firestore_db]


  # lifecycle {
  #   create_before_destroy = true
  #   ignore_changes        = [fields]
  # }
}
