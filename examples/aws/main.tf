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
  }
}

# Provider block for AWS specifies the configuration for the provider
provider "aws" {
  region = "ap-northeast-2"
}
