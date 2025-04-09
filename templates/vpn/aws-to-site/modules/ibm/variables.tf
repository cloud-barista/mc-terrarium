# Note: A required variable is indicated by not specifying a default value.
variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "region" {
  description = "Region for the IBM VPC"
  type        = string
}

variable "vpc_id" {
  description = "value of the IBM VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "value of the IBM subnet ID"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the IBM VPC"
  type        = string
}

variable "aws_vpn_gateway_id" {
  description = "value of the AWS VPN Gateway ID"
  type        = string
}

variable "aws_vpc_cidr_block" {
  description = "CIDR block of the AWS VPC"
  type        = string
}
