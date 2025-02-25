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
  region  = "asia-northeast3"
  zone    = "asia-northeast3-c"
}


# Create SQL MySQL instance
resource "google_sql_database_instance" "my_sql_instance" {
  name             = "my-sql-instance"
  database_version = "MYSQL_8_0" # Specify the MySQL version you need
  # region           = "us-central1"

  settings {
    tier = "db-f1-micro" # Set the instance type
  }

  deletion_protection = false # Disable deletion protection
}

# Create database
resource "google_sql_database" "my_database" {
  name     = "mydatabase"
  instance = google_sql_database_instance.my_sql_instance.name
}

# Create user (optional)
resource "google_sql_user" "my_user" {
  name     = "myuser"
  instance = google_sql_database_instance.my_sql_instance.name
  password = "my-secret-password" # Set a strong password
}
