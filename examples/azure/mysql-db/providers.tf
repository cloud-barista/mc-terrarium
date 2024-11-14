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

resource "azurerm_resource_group" "example" {
  name     = "tofu-example-rg"
  location = var.resource_group_location
}

resource "azurerm_mysql_flexible_server" "example" {
  name                = "tofu-example-mysql-server"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  administrator_login    = "adminuser"
  administrator_password = "Password1234!"

  sku_name = "B_Standard_B1ms" # e.g., General Purpose, Standard_D2s_v3
  # storage_mb = 5120              # 5 GB
  version = "5.7" # MySQL version

  # storage_auto_grow             = "Enabled"
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  # public_network_access_enabled = true

  # Commented out the undeclared resource reference
  # delegated_subnet_id = azurerm_subnet.example.id
}

resource "azurerm_mysql_flexible_database" "example" {
  name                = "tofu-example-db"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mysql_flexible_server.example.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}
