variable "gcp-region" {
  type        = string
  default     = "asia-northeast3"
  description = "Location of the resource group."
}

variable "gcp-zone" {
  type        = string
  default     = "any"
  description = "Location of the resource group."
}

variable "gcp_bgp_asn" {
  description = "The GCP VPC Router ASN"
  type        = string
  default     = "65534"
}