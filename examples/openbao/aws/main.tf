# ==============================================================================
# OpenBao + AWS Example
#
# Demonstrates reading AWS credentials from OpenBao (KV v2)
# and using them to provision AWS resources via OpenTofu.
#
# Prerequisites:
#   1. OpenBao running and unsealed (docker compose up -d openbao)
#   2. Credentials registered (bash init/init.sh)
#   3. VAULT_ADDR and VAULT_TOKEN set
#
# Usage (from this directory):
#   source ../../../.env
#   tofu init
#   tofu plan
#   tofu apply
#   tofu destroy
#
# Note: Inside Docker containers, VAULT_ADDR and VAULT_TOKEN are
#       automatically set by docker-compose.yaml.
# ==============================================================================

terraform {
  required_version = ">=1.8.3"

  required_providers {
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
    vault = {
      source  = "registry.opentofu.org/hashicorp/vault"
      version = "~>4.0"
    }
  }
}

# ── OpenBao Provider (Vault-compatible) ───────────────────────────
# Automatically reads VAULT_ADDR and VAULT_TOKEN from environment.
# Inside Docker: set by docker-compose.yaml
# On host: export VAULT_ADDR and VAULT_TOKEN (or source .env)

provider "vault" {}

# ── Read AWS credentials from OpenBao ─────────────────────────────

data "vault_kv_secret_v2" "aws" {
  mount = "secret"
  name  = "csp/aws"
}

# ── AWS Provider using OpenBao credentials ────────────────────────

provider "aws" {
  region     = "ap-northeast-2"
  access_key = data.vault_kv_secret_v2.aws.data["AWS_ACCESS_KEY_ID"]
  secret_key = data.vault_kv_secret_v2.aws.data["AWS_SECRET_ACCESS_KEY"]
}

# ── AWS Resources (same as examples/aws/basic) ───────────────────

resource "aws_vpc" "example_vpc" {
  cidr_block = "192.168.64.0/22"

  tags = {
    Name = "openbao-example-vpc"
  }
}

resource "aws_subnet" "example_subnet_1" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "192.168.64.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "openbao-example-subnet-1"
  }
}

resource "aws_subnet" "example_subnet_2" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "192.168.65.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "openbao-example-subnet-2"
  }
}

# ── Outputs ───────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID created using OpenBao-managed credentials"
  value       = aws_vpc.example_vpc.id
}

output "credential_source" {
  description = "Where the credentials came from"
  value       = "OpenBao KV v2 → secret/csp/aws"
}
