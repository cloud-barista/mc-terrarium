## GCP variables
# VPC
variable "gcp-vpc-network-name" {
  type        = string
  description = "The VPC network name in GCP."  
  default = "tofu-gcp-vpc"
}

# Subnet
variable "gcp-vpc-subnetwork-name" {
  type        = string
  description = "The subnet name in GCP"
  default = "tofu-gcp-subnet-1"  
}

variable "gcp-region" {
  type        = string
  description = "A region in GCP"
  default     = "asia-northeast3"  
}

variable "gcp-bgp-asn" {
  type        = string
  description = "Autonomous System Number(ASN) for Border Gateway Protocol(BGP) in GCP"
  default     = "65534"
}