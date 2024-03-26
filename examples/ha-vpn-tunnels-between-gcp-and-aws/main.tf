# Define the required version of Terraform and the providers that will be used in the project
terraform {
  # Required Tofu version
  required_version = "1.6.1"

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
  region = "ap-northeast-2"
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
  region  = "asia-northeast3"
  zone    = "asia-northeast3-c"
}
