variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vswitch_id_1" {
  type = string
}

variable "vswitch_id_2" {
  type = string
}

variable "bgp_asn" {
  type    = string
  default = "65532" # default value
}

variable "aws_vpn_gateway_id" {
  type    = string
  default = null
}

variable "aws_vpc_cidr_block" {
  type = string
}
