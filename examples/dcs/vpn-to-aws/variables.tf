# 네이밍
variable "name_prefix" {
  type    = string
  default = "tofu"
}

variable "add_random_suffix" {
  type    = bool
  default = true
}

# AWS
# variable "aws_profile" {
#   type    = string
#   default = "default"
# }

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "aws_vpc_id" {
  type    = string
  default = ""
}

variable "aws_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "aws_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "aws_route_table_ids" {
  type    = list(string)
  default = []
}

variable "aws_bgp_asn" {
  type    = number
  default = 64512
}

# OpenStack
variable "os_router_id" {
  type    = string
  default = ""
}

variable "os_local_cidr" {
  type    = string
  default = "192.168.0.0/24"
}

variable "os_public_ip" {
  type    = string
  default = ""
}

variable "os_subnet_id" {
  type    = string
  default = ""
}

variable "openstack_network_cidr" {
  type    = string
  default = "192.168.0.0/24"
}

variable "openstack_subnet_cidr" {
  type    = string
  default = "192.168.0.0/26"
}

# VPN Configuration
variable "vpn_shared_secret" {
  description = "Pre-shared key for VPN tunnels"
  type        = string
  default     = "MyVPNSharedSecret123!"
  sensitive   = true
}

variable "openstack_bgp_asn" {
  description = "BGP ASN for DCS (OpenStack) side"
  type        = number
  default     = 65000
}


