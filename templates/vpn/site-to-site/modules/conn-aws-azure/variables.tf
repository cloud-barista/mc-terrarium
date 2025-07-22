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
  description = "value of the Azure Resource Group name"
  type        = string
}

variable "azure_bgp_asn" {
  description = "Border Gateway Protocol Autonomous System Number"
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

variable "aws_vpn_gateway_id" {
  description = "value of the AWS VPN Gateway ID"
  type        = string
}
