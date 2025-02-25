# Define the required version of Terraform and the providers that will be used in the project
terraform {
  # Required Tofu version
  required_version = ">=1.8.3"

  required_providers {
    # Google provider is specified with its source and version
    google = {
      source  = "hashicorp/google"
      version = "~>5.21"
    }
  }
}

# CAUTION: Manage your credentials carefully to avoid disclosure.
locals {
  # Read and assign credential JSON string
  my_gcp_credential = file("../../../secrets/credential-gcp.json")
  # Decode JSON string and get project ID
  my_gcp_project_id = jsondecode(local.my_gcp_credential).project_id
}

# Provider block for Google specifies the configuration for the provider
provider "google" {
  credentials = local.my_gcp_credential

  project = local.my_gcp_project_id
  region  = var.csp_region
  # zone    = "asia-northeast3-c"
}

