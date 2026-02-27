# ── OpenBao Provider (Vault-compatible) ───────────────────────────
# Reads VAULT_ADDR and VAULT_TOKEN from environment variables.
provider "vault" {}

# ── Read AWS credentials from OpenBao ─────────────────────────────
data "vault_kv_secret_v2" "aws" {
  mount = "secret"
  name  = "csp/aws"
}

# AWS Provider configuration using OpenBao credentials
provider "aws" {
  region     = var.aws_region
  access_key = data.vault_kv_secret_v2.aws.data["AWS_ACCESS_KEY_ID"]
  secret_key = data.vault_kv_secret_v2.aws.data["AWS_SECRET_ACCESS_KEY"]
}
