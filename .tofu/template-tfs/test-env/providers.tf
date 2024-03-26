# Define the required version of Terraform and the providers that will be used in the project
terraform {
  # Specify the required Tofu version
  required_version = "~>1.6.1"

  # Specify the required providers and their versions
  required_providers {
    # Google provider
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
      version = "~> 5.2"
    }

    # AWS provider is specified with its source and version
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~> 5.21"
    }

    # The Azure Provider
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.92.0"
    }
    # The AzAPI provider
    azapi = {
      source  = "azure/azapi"
      version = "~>1.12"
    }
  }
}

# Provider block for Google specifies the configuration for the provider
# CAUTION: Manage your credentials carefully to avoid disclosure.
locals {
  # Read and assign credential JSON string
  my-gcp-credential = file("credential-gcp.json")
  # Decode JSON string and get project ID
  my-gcp-project-id = jsondecode(local.my-gcp-credential).project_id
}

# Provider block for Google specifies the configuration for the provider
provider "google" {
  credentials = local.my-gcp-credential

  project = local.my-gcp-project-id
  region  = var.gcp-region
}

# The "random" provider allows the use of randomness within Terraform configurations.
# It is used to select a zone in a GCP region randomly.
provider "random" {
  // Optional configuration for the random provider
}

# Provider block for AWS specifies the configuration for the provider
provider "aws" {
  region = var.aws-region
}

module "ubuntu_22_04_latest" {
  source = "github.com/andreswebs/terraform-aws-ami-ubuntu"
}

locals {
  ami_id = module.ubuntu_22_04_latest.ami_id
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

