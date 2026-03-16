# providers.tf
terraform {
  required_version = ">=1.8.3"

  required_providers {
    # IBM Cloud provider
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "~>1.76.0"
    }
    # Time provider for destroy-time delays (IBM Cloud eventual consistency workaround)
    time = {
      source  = "hashicorp/time"
      version = "~>0.11"
    }
  }
}
