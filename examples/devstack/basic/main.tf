# DevStack Basic Infrastructure Example
# This example demonstrates how to create basic networking and compute resources in DevStack (OpenStack)

# Define the required version of OpenTofu and the providers
terraform {
  # Required OpenTofu version
  required_version = ">=1.8.3"

  required_providers {
    # OpenStack provider for DevStack resources
    openstack = {
      source  = "registry.opentofu.org/terraform-provider-openstack/openstack"
      version = "~>1.54"
    }

    # TLS provider for SSH key generation
    tls = {
      source  = "registry.opentofu.org/hashicorp/tls"
      version = "~>4.0"
    }
  }
}

# OpenStack Provider Configuration for DevStack
# Uses environment variables: OS_USERNAME, OS_PROJECT_NAME, OS_PASSWORD, OS_AUTH_URL, OS_REGION_NAME
provider "openstack" {
  # Configuration will be read from environment variables
  # Make sure to source the credential file before running:
  # source ../../secrets/load-openstack-cred-env.sh
}


