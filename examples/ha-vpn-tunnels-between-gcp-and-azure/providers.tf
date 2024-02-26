# Define the required version of Terraform and the providers that will be used in the project
terraform {
  # Required Tofu version
  required_version = "1.6.1"

  required_providers {
    # Google provider is specified with its source and version
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
      version = "~> 5.2"
    }

    # Azure provider is specified with its source and version
    azapi = {
      source  = "azure/azapi"
      version = "~>1.12"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.92.0"
    }
  }
}

# Provider block for Google specifies the configuration for the provider
# CAUTION: Manage your credentials carefully to avoid disclosure.
locals {
  # Read and assign credential JSON string
  my_gcp_credential = file("credential-gcp.json")
  # Decode JSON string and get project ID
  my_gcp_project_id = jsondecode(local.my_gcp_credential).project_id
}

# Provider block for Google specifies the configuration for the provider
provider "google" {
  credentials = local.my_gcp_credential

  project = local.my_gcp_project_id
  region  = var.gcp-region
  zone    = var.gcp-zone
}

# Ref.) Azure Provider: Authenticating using a Service Principal with a Client Secret
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret


# Configure the Microsoft Azure Provider
provider "azurerm" {
  # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  skip_provider_registration = true 
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "my-azure-resource-group" {
  name     = "my-azure-resource-group-name"
  # Default: "koreacentral"
  location = var.azure-region
}
