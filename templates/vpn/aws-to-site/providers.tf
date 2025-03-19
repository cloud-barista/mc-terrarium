# providers.tf
terraform {
  required_version = ">=1.8.3"

  required_providers {
    # AWS provider
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
    # Google provider
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
      version = "~>5.21"
    }
    # Azure provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.97.0"
    }
    # AzAPI provider
    azapi = {
      source  = "azure/azapi"
      version = "~>1.12"
    }
    # Alibaba Cloud provider
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~>1.243.0"
    }
    # IBM Cloud provider
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.76.0"
    }
    # Tencent Cloud provider
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~>1.81.173"
    }
  }
}

provider "aws" {
  region = var.vpn_config.aws.region
}

provider "google" {
  credentials = file("credential-gcp.json")
  project     = jsondecode(file("credential-gcp.json")).project_id
  region      = local.is_gcp ? var.vpn_config.target_csp.gcp.region : "asia-northeast3" # Seoul
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
  region = local.is_alibaba ? var.vpn_config.target_csp.alibaba.region : "ap-northeast-2"
}

provider "ibm" {
  region = local.is_ibm ? var.vpn_config.target_csp.ibm.region : "au-syd" # Sydney region, Australia
}

# Configure the Tencent Cloud Provider
provider "tencentcloud" {
  region = local.is_tencent ? var.vpn_config.target_csp.tencent.region : "ap-seoul" # Seoul region
}
