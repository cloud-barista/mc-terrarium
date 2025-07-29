# Note: A required variable is indicated by not specifying a default value.
variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "shared_secret" {
  description = "Shared secret for VPN connection"
  type        = string
  sensitive   = true
}

# Azure Configuration
variable "azure_region" {
  description = "Region for the Azure resources"
  type        = string
  default     = "koreacentral" # default value  
}

variable "azure_resource_group_name" {
  description = "value of the Azure Resource Group name"
  type        = string
}

variable "azure_bgp_asn" {
  description = "Border Gateway Protocol Autonomous System Number for Azure"
  type        = string
  default     = "65531" # default value
}

variable "azure_virtual_network_gateway_id" {
  description = "value of the Azure Virtual Network Gateway ID"
  type        = string
}

variable "azure_public_ip_addresses" {
  description = "List of public IP addresses for Azure VPN Gateway"
  type        = list(string)
}

variable "azure_apipa_cidrs" {
  description = "List of APIPA CIDRs for Azure-GCP VPN tunnel interfaces"
  type        = list(string)
  default     = ["169.254.21.0/30", "169.254.21.4/30", "169.254.22.0/30", "169.254.22.4/30"]
}

# GCP Configuration
variable "gcp_bgp_asn" {
  description = "Border Gateway Protocol Autonomous System Number for GCP"
  type        = string
  default     = "65530" # default value
}

variable "gcp_ha_vpn_gateway_self_link" {
  description = "Self link of the GCP HA VPN Gateway"
  type        = string
}

variable "gcp_router_name" {
  description = "Name of the GCP Cloud Router"
  type        = string
}

variable "gcp_vpn_gateway_addresses" {
  description = "List of GCP HA VPN Gateway IP addresses"
  type        = list(string)
}
