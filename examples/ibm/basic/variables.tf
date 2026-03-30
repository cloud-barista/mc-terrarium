variable "credential_profile" {
  type        = string
  description = "The name of the credential profile (holder) to use."
  default     = "admin"
}

variable "region" {
  description = "IBM Cloud region"
  type        = string
  default     = "jp-tok" # Tokyo, Japan
}
