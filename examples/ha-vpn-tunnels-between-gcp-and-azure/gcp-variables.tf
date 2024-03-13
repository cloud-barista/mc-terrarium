variable "my-gcp-region" {
  type        = string
  default     = "asia-northeast3"
  description = "Location of the resource group."
}

# variable "gcp-zone" {
#   type        = string
#   default     = "any"
#   description = "Location of the resource group."
# }

data "google_compute_zones" "my-gcp-available-zones" {
  region = var.my-gcp-region 
}

variable "my-gcp-bgp-asn" {
  description = "The GCP VPC Router ASN"
  type        = string
  default     = "65534"
}