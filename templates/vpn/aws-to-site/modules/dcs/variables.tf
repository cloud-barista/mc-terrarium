variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "router_id" {
  description = "ID of the OpenStack Router"
  type        = string
}

variable "subnet_id" {
  description = "ID of the OpenStack Subnet"
  type        = string
}

variable "bgp_asn" {
  description = "BGP ASN for DCS (OpenStack) side"
  type        = string
  default     = "65000"
}

variable "aws_vpn_gateway_id" {
  description = "ID of the AWS VPN Gateway"
  type        = string
}

variable "aws_vpc_cidr" {
  description = "CIDR block of the AWS VPC"
  type        = string
}
