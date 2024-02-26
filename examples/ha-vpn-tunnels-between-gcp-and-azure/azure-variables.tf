variable "azure-region" {
  type        = string
  # Azure regions mapping list:
  # https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md
  default     = "koreacentral"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "azure_bgp_asn" {
  description = "The Azure BGP ASN"
  type        = string
  default     = "65515"
}

variable "azure_vpn_allowed_az_skus" {
  description = "List of allowed SKU values"
  type        = list(string)
  default     = ["VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ"]
}

variable "azure_vpn_sku" {
  type        = string
  default     = "VpnGw1"
  description = "The Azure VPN Sku/Size"
}

#####
variable "username" {
  description = "The username for the virtual machine."
  type        = string
  default     = "cb-user"
}

# Shared secret
variable "shared_secret" {
  description = "The shared secret for the VPN connection."
  type        = string
  sensitive   = true
  default     = "1234567890"
}