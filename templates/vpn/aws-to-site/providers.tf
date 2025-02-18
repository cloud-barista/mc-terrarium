# providers.tf
terraform {
  required_version = "~>1.8.3"

  required_providers {
    # AWS provider
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
    # Google provider
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
      version = "~>5.21"
    }
    # Azure provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.97.0"
    }
    # AzAPI provider
    azapi = {
      source  = "azure/azapi"
      version = "~>1.12"
    }
  }
}

provider "aws" {
  region = var.vpn_config.aws.region
}

provider "google" {
  credentials = local.is_gcp ? file("credential-gcp.json") : null
  project     = local.is_gcp ? jsondecode(file("credential-gcp.json")).project_id : null
  region      = local.is_gcp ? var.vpn_config.target_csp.gcp.region : "asia-northeast3" # Seoul
}

# [NOTE]
# Ref.) Azure Provider: Authenticating using a Service Principal with a Client Secret
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret

# Configure the Microsoft Azure Provider
provider "azurerm" {
  # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  skip_provider_registration = true
  features {}
}

