# Define the required version of OpenTofu and the providers that will be used in the project
terraform {
  # Required Tofu version
  required_version = ">=1.8.3"

  required_providers {
    # AWS provider is specified with its source and version
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
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

# Read AWS credentials from OpenBao
data "vault_kv_secret_v2" "aws" {
  mount = "secret"
  name  = "csp/aws"
}

# Provider block for AWS specifies the configuration for the provider
provider "aws" {
  region     = var.csp_region
  access_key = data.vault_kv_secret_v2.aws.data["AWS_ACCESS_KEY_ID"]
  secret_key = data.vault_kv_secret_v2.aws.data["AWS_SECRET_ACCESS_KEY"]
}
