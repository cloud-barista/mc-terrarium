## GCP variables
# VPC
variable "gcp-vpc-network-name" {
  type        = string
  description = "The VPC network name in GCP."  
  default = "tofu-gcp-vpc"
}

data "google_compute_network" "injected_vpc_network" {
  name = var.gcp-vpc-network-name
}

# Subnet
variable "gcp-vpc-subnetwork-name" {
  type        = string
  description = "The subnet name in GCP"
  default = "tofu-gcp-subnet-1"  
}

data "google_compute_subnetwork" "injected_vpc_subnetwork" {
  name = var.gcp-vpc-subnetwork-name
}

variable "gcp-region" {
  type        = string
  description = "A region in GCP"
  default     = "asia-northeast3"  
}

// Fetch the available zones in the region
data "google_compute_zones" "gcp_available_zones" {
  region = var.gcp-region 
}

variable "gcp_bgp_asn" {
  type        = string
  description = "Autonomous System Number(ASN) for Border Gateway Protocol(BGP) in GCP"
  default     = "65534"
}