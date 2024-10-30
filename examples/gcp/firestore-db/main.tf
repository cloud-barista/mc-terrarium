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

# Provider block for Google specifies the configuration for the provider
provider "google" {
  credentials = local.my_gcp_credential

  project = local.my_gcp_project_id
  region  = local.my_region
  zone    = "${local.my_region}-c"
}


# Enable Firestore API (Firestore requires this API to be enabled)
resource "google_project_service" "tofu_example_firestore" {
  # project = "<YOUR_PROJECT_ID>"
  service = "firestore.googleapis.com"
}

# "(default)" is required to create a Firestore database
resource "google_firestore_database" "tofu_example_firestore_db" {
  # count = length([for db in google_firestore_database.tofu_example_firestore_db : db if db.name == "(default)"]) == 0 ? 1 : 0
  name = "tofu-example-db" # Firestore database name.  default is "(default)"
  # project    = local.my_gcp_project_id
  location_id = local.my_region
  type        = "FIRESTORE_NATIVE"
}

# Firestore index creation (optional)
resource "google_firestore_index" "tofu_example_index" {
  project    = local.my_gcp_project_id
  collection = "tofu-example-collection-name" # Collection for which the index is created
  fields {
    field_path = "field_1"
    order      = "ASCENDING"
  }
  fields {
    field_path = "field_2"
    order      = "DESCENDING"
  }

  # Ensure the index is created only after the database is available
  depends_on = [google_firestore_database.tofu_example_firestore_db]


  # lifecycle {
  #   create_before_destroy = true
  #   ignore_changes        = [fields]
  # }
}
