# Terraform and Azure Provider configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Data source to get existing Resource Group
data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

# Data source to get existing VNet
data "azurerm_virtual_network" "existing" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

# Data source to get existing subnet
data "azurerm_subnet" "existing" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

# Create AKS cluster using existing infrastructure
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  dns_prefix          = var.dns_prefix

  # Default node pool configuration
  default_node_pool {
    name           = "default"
    node_count     = 2                # 2 worker nodes
    vm_size        = "Standard_D2_v2" # Good general-purpose VM size
    vnet_subnet_id = data.azurerm_subnet.existing.id
  }

  # Network profile configuration (required when using existing VNet)
  network_profile {
    network_plugin = "azure"
    service_cidr   = var.service_cidr
    dns_service_ip = var.dns_service_ip
  }

  # Cluster identity configuration (using system-managed identity)
  # Required permissions for AKS to access other Azure resources (e.g., storage, network)
  identity {
    type = "SystemAssigned"
  }
}
