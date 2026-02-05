variable "terrarium_id" {
  description = "Unique ID to distinguish and manage infrastructure."
  type        = string
}

variable "public_key" {
  description = "Public key for SSH access"
  type        = string
}

variable "image_name" {
  description = "Name regex of the image to use for the instance"
  type        = string
  default     = "(?i)ubuntu.*22" # Regex to match Ubuntu 22.04
}

variable "flavor_name" {
  description = "Name of the flavor to use for the instance"
  type        = string
  default     = "m1.small" # Adjust based on DCS environment
}

variable "external_network_name" {
  description = "Name of the external network"
  type        = string
  default     = "public"
}
