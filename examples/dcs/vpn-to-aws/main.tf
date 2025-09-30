# VPN Site-to-Site Connection between AWS and DCS (Data Center Simulator)
# This example demonstrates how to establish IPsec VPN tunnels between AWS and DCS

# Define the required version of OpenTofu and the providers
terraform {
  # Required OpenTofu version
  required_version = ">=1.8.3"

  required_providers {
    # AWS provider for AWS resources
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }

    # OpenStack provider for DCS resources
    openstack = {
      source  = "registry.opentofu.org/terraform-provider-openstack/openstack"
      version = "~>1.54"
    }

    # TLS provider for key generation
    tls = {
      source  = "registry.opentofu.org/hashicorp/tls"
      version = "~>4.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
}

# OpenStack Provider Configuration for DCS
# Uses environment variables: OS_USERNAME, OS_PROJECT_NAME, OS_PASSWORD, OS_AUTH_URL, OS_REGION_NAME
provider "openstack" {
  # Configuration will be read from environment variables
  # Make sure to source the credential file before running:
  # source ../../secrets/load-openstack-cred-env.sh
}

# Generate SSH key pair for instances (shared between AWS and OpenStack)
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create AWS Key Pair using the shared SSH key
resource "aws_key_pair" "main" {
  key_name   = "${var.name_prefix}-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = {
    Name = "${var.name_prefix}-key"
  }
}

# Create OpenStack Key Pair using the same SSH key
resource "openstack_compute_keypair_v2" "main" {
  name       = "${var.name_prefix}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

# Note: APIPA addresses are now auto-assigned by AWS
# No need to manually specify tunnel inside CIDRs
# All configuration is managed through variables
