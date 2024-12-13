variable "terrarium_id" {
  type        = string
  description = "Unique ID to distinguish and manage infrastructure."
  # default     = "terrarium01" # # Used for testing

  validation {
    condition     = var.terrarium_id != ""
    error_message = "The terrarium ID must be set"
  }
}

#######################################################################
# Amazon Web Services (AWS)
variable "csp_region" {
  type        = string
  description = "A region in AWS."
  default     = "ap-northeast-2"
  # AWS regions mapping list:
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html
}

# Required network information
variable "csp_vnet_id" {
  type        = string
  description = "The VPC ID in AWS."
}

# (Required) Username of the user.
variable "username" {
  type        = string
  description = "The username for the message broker."
  default     = "mybrokeruser1"
}

# (Required) Password of the user. 
# It must be 12 to 250 characters long, at least 4 unique characters, and must not contain commas.
variable "password" {
  type        = string
  description = "The password for the message broker." #
  default     = "Pa$$word1234Secure!"
}
