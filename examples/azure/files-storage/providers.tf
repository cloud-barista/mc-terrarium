# Define the required version of Terraform and the providers that will be used in the project
terraform {
  # Required Tofu version
  required_version = "~>1.8.3"

  required_providers {
    # Azure provider is specified with its source and version
    azapi = {
      source  = "azure/azapi"
      version = "~>1.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.97.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

# Ref.) Azure Provider: Authenticating using a Service Principal with a Client Secret
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret


# Configure the Microsoft Azure Provider
provider "azurerm" {
  # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  skip_provider_registration = true
  features {}
}

variable "resource_group_location" {
  type        = string
  default     = "koreacentral"
  description = "Location of the resource group."
}


# 리소스 그룹 생성
resource "azurerm_resource_group" "example" {
  name     = "tofu-example-rg"
  location = var.resource_group_location
}


# 랜덤 문자열 생성
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false # 대문자를 사용하지 않도록 설정
}

# Storage Account 생성
resource "azurerm_storage_account" "example" {
  name                     = "tofuacct${random_string.suffix.result}" # Globally unique name, only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally Redundant Storage

}

# 파일 공유 생성
resource "azurerm_storage_share" "example" {
  name                 = "tofu-example-share"
  storage_account_name = azurerm_storage_account.example.name
  quota                = 50 # 공유 용량 (GB 단위)
}
