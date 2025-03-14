# providers.tf
terraform {
  required_version = ">=1.8.3"

  required_providers {
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
      version = "~>5.21"
    }
    # The Azure Provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.97.0"
    }
    # The AzAPI provider
    azapi = {
      source  = "azure/azapi"
      version = "~>1.12"
    }
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~>1.243.0"
    }
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~>1.76.0"
    }
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~>1.81.173"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2" # Seoul
}

provider "google" {
  credentials = file("credential-gcp.json")
  project     = jsondecode(file("credential-gcp.json")).project_id
  region      = "asia-northeast3" # Seoul
}

# [NOTE]
# Ref.) Azure Provider: Authenticating using a Service Principal with a Client Secret
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret

# Configure the Microsoft Azure Provider
provider "azurerm" {
  # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  skip_provider_registration = true
  features {}
}

# Configure the Alibaba Cloud Provider
provider "alicloud" {
  region = "ap-northeast-2" # Seoul
}

# Configure the IBM Cloud Provider
provider "ibm" {
  region = "au-syd" # Sydney region
}

# Configure the Tencent Cloud Provider
provider "tencentcloud" {
  region = "ap-seoul" # Seoul region
}

# SSH key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
