# Define the required version of Terraform and the providers that will be used in the project
terraform {
  # Required Tofu version
  required_version = ">=1.8.3"

  required_providers {
    # AWS provider is specified with its source and version
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }

    # Google provider is specified with its source and version
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
      version = "~>5.21"
    }
  }
}

# Provider block for AWS specifies the configuration for the provider
provider "aws" {
  region = var.aws-region
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
