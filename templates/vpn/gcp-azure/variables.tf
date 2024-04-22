variable "resource-group-id" {
  type        = string
  description = "Unique ID to distinguish and manage infrastructure."

  validation {
    condition     = var.resource-group-id != ""
    error_message = "The resource group ID must be set"
  }
}

#######################################################################
# Google Cloud Platform (GCP)
variable "gcp-region" {
  type        = string
  description = "A region in GCP"
  default     = "asia-northeast3"  
}

variable "gcp-vpc-network-name" {
  type        = string
  description = "The VPC network name in GCP."  
  default = "tofu-gcp-vpc"
}

# variable "gcp-vpc-subnetwork-name" {
#   type        = string
#   description = "The subnet name in GCP"
#   default = "tofu-gcp-subnet-1"  
# }

variable "gcp-bgp-asn" {
  type        = string
  description = "Autonomous System Number(ASN) for Border Gateway Protocol(BGP) in GCP"
  default     = "65534"
}

#######################################################################
# Microsoft Azure (MS Azure / Azure)

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

variable "azure-virtual-network-name" {
  type        = string
  description = "A virtual network name in MS Azure."
  default     = "tofu-azure-vnet"
}

variable "azure-gateway-subnet-cidr-block" {
  type        = string
  description = "The CIDR block for the gateway subnet."
  default     = "192.168.130.0/24"  
}

# variable "azure-subnet-name" {
#   type        = string
#   description = "Subnet name in MS Azure"
#   default     = ".tofu/tofu-rg-01/vpn/gcp-azure/azure-variables.tf .tofu/tofu-rg-01/vpn/gcp-azure/azure-virtual-machine.tf"
# }

# variable "azure-gateway-subnet-name" {
#   type        = string
#   description = "Gateway subnet name in MS Azure. Must be GatewaySubnet."
#   default     = "GatewaySubnet"
#   validation {
#     condition     = var.azure-gateway-subnet-name == "GatewaySubnet"
#     error_message = "The gateway subnet name must be GatewaySubnet"
#   }
# }

variable "azure-bgp-asn" {
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
variable "preshared-secret" {
  description = "The shared secret for the VPN connection."
  type        = string
  sensitive   = true
  default     = "1234567890"
}