# Configure the Google Cloud Provider
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Configure GCP Provider
provider "google" {
  credentials = file("credential-gcp.json")
  project     = jsondecode(file("credential-gcp.json")).project_id
  region      = var.vpn_config.gcp.region
}
