variable "terrarium_id" {
  type = string
}

variable "public_key" {
  type = string
}

variable "gcp_project_id" {
  description = "GCP project ID (from OpenBao)"
  type        = string
  default     = ""
}
