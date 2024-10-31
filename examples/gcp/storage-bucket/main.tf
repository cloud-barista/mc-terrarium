# Define the required version of Terraform and the providers that will be used in the project
terraform {
  # Required Tofu version
  required_version = "~>1.8.3"

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

  # Define the region as a local variable to reuse it across resources
  my_region = "asia-northeast3"
}

# NOTE: locaion 범위에 따라 값이 상이함 
# * Regional: us-central1, europe-west1, asia-east1.
# * Dual-region: nam4 (미국 내 뉴버지니아와 오리건), eur4 (유럽 내 벨기에와 핀란드)
# * Multi-regionUS (미국 전역), EU (유럽 전역), ASIA (아시아 전역).

# Provider block for Google specifies the configuration for the provider
provider "google" {
  credentials = local.my_gcp_credential

  project = local.my_gcp_project_id
  region  = local.my_region
  zone    = "${local.my_region}-c"
}

resource "google_storage_bucket" "tofu_example_bucket" {
  name                        = "tofu-example-bucket"
  location                    = local.my_region
  force_destroy               = true
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}
