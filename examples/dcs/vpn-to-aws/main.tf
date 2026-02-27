# VPN Site-to-Site Connection between AWS and DCS (Data Center Simulator)
# This example demonstrates how to establish IPsec VPN tunnels between AWS and DCS

# Define the required version of OpenTofu and the providers
terraform {
  # Required OpenTofu version
  required_version = ">=1.8.3"

  required_providers {
    # AWS provider for AWS resources
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }

    # OpenStack provider for DCS resources
    openstack = {
      source  = "registry.opentofu.org/terraform-provider-openstack/openstack"
      version = "~>1.54"
    }

    # TLS provider for key generation
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

# ── Read AWS credentials from OpenBao ─────────────────────────────
data "vault_kv_secret_v2" "aws" {
  mount = "secret"
  name  = "csp/aws"
}

# ── Read OpenStack credentials from OpenBao ──────────────────────
data "vault_kv_secret_v2" "openstack" {
  mount = "secret"
  name  = "csp/openstack"
}

# ── AWS Provider using OpenBao credentials ────────────────────────
provider "aws" {
  region     = var.aws_region
  access_key = data.vault_kv_secret_v2.aws.data["AWS_ACCESS_KEY_ID"]
  secret_key = data.vault_kv_secret_v2.aws.data["AWS_SECRET_ACCESS_KEY"]
}

# ── OpenStack Provider using OpenBao credentials ────────────────
provider "openstack" {
  auth_url    = data.vault_kv_secret_v2.openstack.data["OS_AUTH_URL"]
  user_name   = data.vault_kv_secret_v2.openstack.data["OS_USERNAME"]
  password    = data.vault_kv_secret_v2.openstack.data["OS_PASSWORD"]
  domain_name = data.vault_kv_secret_v2.openstack.data["OS_DOMAIN_NAME"]
  tenant_name = data.vault_kv_secret_v2.openstack.data["OS_PROJECT_NAME"]
}

# Generate SSH key pair for instances (shared between AWS and OpenStack)
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create AWS Key Pair using the shared SSH key
resource "aws_key_pair" "main" {
  key_name   = "${var.name_prefix}-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = {
    Name = "${var.name_prefix}-key"
  }
}

# Create OpenStack Key Pair using the same SSH key
resource "openstack_compute_keypair_v2" "main" {
  name       = "${var.name_prefix}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

# Note: APIPA addresses are now auto-assigned by AWS
# No need to manually specify tunnel inside CIDRs
# All configuration is managed through variables

resource "random_id" "suffix" {
  count       = var.add_random_suffix ? 1 : 0
  byte_length = 2
}
