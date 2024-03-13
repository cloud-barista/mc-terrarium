variable "my-azure-region" {
  type        = string
  # Azure regions mapping list:
  # https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md
  default     = "koreacentral"
  description = "Location of the resource group."
}

# variable "resource_group_name_prefix" {
#   type        = string
#   default     = "rg"
#   description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
# }

variable "my-azure-bgp-asn" {
  description = "The Azure BGP ASN"
  type        = string
  default     = "65515"
}

variable "my-azure-vpn-allowed-az-skus" {
  description = "List of allowed SKU values"
  type        = list(string)
  default     = ["VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ"]
}

variable "my-azure-vpn-sku" {
  type        = string
  default     = "VpnGw1"
  description = "The Azure VPN Sku/Size"
}

#####
# variable "username" {
#   description = "The username for the virtual machine."
#   type        = string
#   default     = "ubuntu"
# }

# Shared secret
variable "my-shared-secret" {
  description = "The shared secret for the VPN connection."
  type        = string
  sensitive   = true
  default     = "1234567890"
}