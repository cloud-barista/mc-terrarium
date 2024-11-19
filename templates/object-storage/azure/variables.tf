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
# Microsoft Azure (MS Azure / Azure)

variable "csp_region" {
  type        = string
  description = "A location (region) in MS Azure."
  default     = "koreacentral"
  # Azure regions mapping list:
  # https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md  
}

variable "csp_resource_group" {
  type        = string
  default     = "koreacentral"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}
