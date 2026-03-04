variable "terrarium_id" {
  type = string
}

variable "vpc_cidr" {
  type        = string
  description = "Logical CIDR block for the IBM VPC (used for VPN routing and address prefix management)"
  default     = "10.4.0.0/16"
}

variable "public_key" {
  type = string
}
