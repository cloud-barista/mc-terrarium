# providers.tf
terraform {
  required_version = ">=1.8.3"

  required_providers {
    # Google provider
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
      version = "~>5.21"
    }
  }
}
