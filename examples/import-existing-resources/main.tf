# Define the required version of Terraform and the providers that will be used in the project
terraform {
  required_version = "1.7.1"

  required_providers {
    # AWS provider is specified with its source and version
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.42"
    }

    # Google provider is specified with its source and version
    google = {
      source  = "hashicorp/google"
      version = "~>5.21"
    }
  }
}
