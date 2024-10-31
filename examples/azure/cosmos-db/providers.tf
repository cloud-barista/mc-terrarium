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

variable "cosmos_db_account_name" {
  description = "The name of the Cosmos DB account."
  default     = "tofu-example-cosmosdb"
}

// 리소스 그룹 생성
resource "azurerm_resource_group" "example" {
  name     = "tofu-example-rg"
  location = var.resource_group_location
}

// Cosmos DB 계정 생성
resource "azurerm_cosmosdb_account" "example" {
  name                = var.cosmos_db_account_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "Session"
    max_staleness_prefix    = 100
    max_interval_in_seconds = 5
  }

  geo_location {
    location          = azurerm_resource_group.example.location
    failover_priority = 0
  }
}

// Cosmos DB 데이터베이스 생성
resource "azurerm_cosmosdb_sql_database" "example" {
  name                = "tofu-example-database"
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_cosmosdb_account.example.name
}

