variable "terrarium_id" {
  type        = string
  description = "Unique ID to distinguish and manage infrastructure."
  default     = "terrarium01"

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

# # Required network information
# variable "csp_vnet_id" {
#   type        = string
#   description = "The VPC ID in AWS."
# }
