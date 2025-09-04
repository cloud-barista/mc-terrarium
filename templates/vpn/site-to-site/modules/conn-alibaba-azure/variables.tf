# Note: A required variable is indicated by not specifying a default value.
variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "azure_region" {
  description = "Region for the Azure resources"
  type        = string
  default     = "koreacentral" # default value
}

variable "azure_resource_group_name" {
  description = "Azure Resource Group name"
  type        = string
}

variable "azure_bgp_asn" {
  description = "Azure Border Gateway Protocol Autonomous System Number"
  type        = string
  default     = "65531" # default value
}

variable "azure_virtual_network_gateway_id" {
  description = "Azure Virtual Network Gateway ID"
  type        = string
}

variable "azure_public_ip_addresses" {
  description = "List of public IP addresses for Azure VPN Gateway"
  type        = list(string)
}

variable "azure_apipa_cidrs" {
  description = "List of APIPA CIDRs for Azure VPN Gateway"
  type        = list(string)
  default     = ["169.254.25.0/30", "169.254.25.4/30", "169.254.26.0/30", "169.254.26.4/30"]
}

variable "alibaba_vpn_gateway_id" {
  description = "Alibaba VPN Gateway ID"
  type        = string
}

variable "alibaba_vpc_id" {
  description = "Alibaba VPC ID"
  type        = string
}

variable "azure_virtual_network_cidr" {
  description = "Azure Virtual Network CIDR block"
  type        = string
}

variable "alibaba_vpn_gateway_internet_ip" {
  description = "Internet IP of the Alibaba VPN Gateway"
  type        = string
}

variable "alibaba_bgp_asn" {
  description = "Alibaba Border Gateway Protocol Autonomous System Number"
  type        = string
  default     = "65532" # default value
}

variable "shared_secret" {
  description = "Shared secret for VPN connections"
  type        = string
  default     = "terraform-vpn-shared-secret"
}
