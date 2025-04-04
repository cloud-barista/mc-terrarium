# providers.tf
terraform {
  required_version = ">=1.8.3"

  required_providers {
    # AWS provider
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
  }
}
