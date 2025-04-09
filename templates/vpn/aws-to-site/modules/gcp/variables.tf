# Note: A required variable is indicated by not specifying a default value.
variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "vpc_network_name" {
  description = "Name of the GCP VPC network"
  type        = string
}

variable "bgp_asn" {
  description = "Border Gateway Protocol Autonomous System Number"
  type        = string
  default     = "65530" # default value
}

variable "aws_vpn_gateway_id" {
  description = "ID of the AWS VPN Gateway"
  type        = string
}
