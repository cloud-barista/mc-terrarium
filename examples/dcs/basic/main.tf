# DevStack Basic Infrastructure Example
# This example demonstrates how to create basic networking and compute resources in DevStack (OpenStack)

# Define the required version of OpenTofu and the providers
terraform {
  # Required OpenTofu version
  required_version = ">=1.8.3"

  required_providers {
    # OpenStack provider for DevStack resources
    openstack = {
      source  = "registry.opentofu.org/terraform-provider-openstack/openstack"
      version = "~>1.54"
    }

    # TLS provider for SSH key generation
    tls = {
      source  = "registry.opentofu.org/hashicorp/tls"
      version = "~>4.0"
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

# ── Read OpenStack credentials from OpenBao ──────────────────────
data "vault_kv_secret_v2" "openstack" {
  mount = "secret"
  name  = "csp/openstack"
}

# ── OpenStack Provider using OpenBao credentials ────────────────
provider "openstack" {
  auth_url    = data.vault_kv_secret_v2.openstack.data["OS_AUTH_URL"]
  user_name   = data.vault_kv_secret_v2.openstack.data["OS_USERNAME"]
  password    = data.vault_kv_secret_v2.openstack.data["OS_PASSWORD"]
  domain_name = data.vault_kv_secret_v2.openstack.data["OS_DOMAIN_NAME"]
  tenant_name = data.vault_kv_secret_v2.openstack.data["OS_PROJECT_NAME"]
}


