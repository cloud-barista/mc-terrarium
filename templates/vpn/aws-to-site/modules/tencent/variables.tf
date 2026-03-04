# Note: A required variable is indicated by not specifying a default value.
variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources"
}

variable "vpc_id" {
  type        = string
  description = "value of the Tencent VPC ID"
}

variable "aws_vpn_gateway_id" {
  type        = string
  description = "value of the AWS VPN Gateway ID"
}

variable "aws_vpc_cidr_block" {
  type        = string
  description = "CIDR block of the AWS VPC"
}

variable "tencent_bgp_asn" {
  type        = number
  description = "BGP ASN for the Tencent Cloud side (used in AWS Customer Gateway)"
  default     = 65000
}
