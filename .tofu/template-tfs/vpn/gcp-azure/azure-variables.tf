
# # Create a resource group
# resource "azurerm_resource_group" "injected_rg" {
#   name     = "${}"
#   # Default: "koreacentral"
#   location = var.azure-region
# }

variable "azure-region" {
  type        = string
  description = "A location (region) in MS Azure."
  default     = "koreacentral"
  # Azure regions mapping list:
  # https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md  
}

variable "azure-resource-group-name" {
  type        = string
  default     = "tofu-rg-01"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

data "azurerm_resource_group" "injected_rg" {
  name = var.azure-resource-group-name
}

variable "azure-virtual-network-name" {
  type        = string
  description = "A virtual network name in MS Azure."
  default     = "tofu-azure-vnet"
}

data "azurerm_virtual_network" "injected_vnet" {
  name                = var.azure-virtual-network-name
  resource_group_name = data.azurerm_resource_group.injected_rg.name
}

variable "azure-gateway-subnet-name" {
  type        = string
  description = "Gateway subnet name in MS Azure. Must be GatewaySubnet."
  default     = "GatewaySubnet"
  validation {
    condition     = var.azure-gateway-subnet-name == "GatewaySubnet"
    error_message = "The gateway subnet name must be GatewaySubnet"
  }
}

data "azurerm_subnet" "injected_gw_subnet" {
  name                 = var.azure-gateway-subnet-name
  virtual_network_name = data.azurerm_virtual_network.injected_vnet.name
  resource_group_name  = data.azurerm_resource_group.injected_rg.name
}

variable "azure_bgp_asn" {
  type        = string
  description = "Autonomous System Number(ASN) for Border Gateway Protocol(BGP) in MS Azure"  
  default     = "65515"
}

variable "azure_vpn_allowed_az_skus" {
  description = "List of allowed Stock Keeping Unit (SKU) values"
  type        = list(string)
  default     = ["VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ"]
}

variable "azure_vpn_sku" {
  type        = string
  description = "The Azure VPN Sku/Size"
  default     = "VpnGw1"  
}

# Shared secret
variable "preshared_secret" {
  description = "The shared secret for the VPN connection."
  type        = string
  sensitive   = true
  default     = "1234567890"
}