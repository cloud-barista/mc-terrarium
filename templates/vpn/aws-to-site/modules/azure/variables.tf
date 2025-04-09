# Note: A required variable is indicated by not specifying a default value.
variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "region" {
  description = "Region for the Azure resources"
  type        = string
  default     = "koreacentral" # default value  
}

variable "resource_group_name" {
  description = "value of the Azure Resource Group name"
  type        = string
}

variable "virtual_network_name" {
  description = "value of the Azure Virtual Network name"
  type        = string
}

variable "gateway_subnet_cidr" {
  description = "CIDR block for the Gateway Subnet"
  type        = string
}

variable "vpn_sku" {
  description = "value of the Azure VPN Gateway SKU"
  type        = string
  default     = "VpnGw1AZ" # default value
}

variable "bgp_asn" {
  description = "Border Gateway Protocol Autonomous System Number"
  type        = string
  default     = "65531" # default value
}

variable "aws_vpn_gateway_id" {
  description = "value of the AWS VPN Gateway ID"
  type        = string
}
