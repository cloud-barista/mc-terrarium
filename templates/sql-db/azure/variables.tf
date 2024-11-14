variable "terrarium_id" {
  type        = string
  description = "Unique ID to distinguish and manage infrastructure."

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
  default     = "tr-rg-01"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

# variable "azure-virtual-network-name" {
#   type        = string
#   description = "A virtual network name in MS Azure."
#   default     = "tr-azure-vnet"
# }

# # Required network information
# variable "csp_vnet_id" {
#   type        = string
#   description = "The VPC ID in AWS."
# }

# variable "csp_subnet1_id" {
#   type        = string
#   description = "The subnet ID in Azure."
# }

# variable "csp_subnet2_id" {
#   type        = string
#   description = "The subnet ID in AWS."
# }

# # Required security group information
# variable "db_engine_port" {
#   type        = number
#   description = "The port number for the database engine."
#   default     = 3306
# }

# variable "ingress_cidr_block" {
#   type        = string
#   description = "The CIDR block for ingress traffic."
#   default     = "0.0.0.0/0"
# }

# variable "egress_cidr_block" {
#   type        = string
#   description = "The CIDR block for egress traffic."
#   default     = "0.0.0.0/0"
# }

# # Required database engine information
# variable "db_instance_identifier" {
#   type        = string
#   description = "The identifier for the database."
#   default     = "mydbinstance"
# }

variable "db_engine_version" {
  type        = string
  description = "The version of the database engine."
  default     = "8.0.21"
}

variable "db_instance_spec" {
  type        = string
  description = "The instance class for the database."
  default     = "B_Standard_B1ms"
}

variable "db_admin_username" {
  type        = string
  description = "The admin username for the database."
  default     = "mydbadmin"
}

# NOTE - "administrator_password" must contain characters from three of the categories 
# – uppercase letters, lowercase letters, numbers and non-alphanumeric characters, got mysdbpass
variable "db_admin_password" {
  type        = string
  description = "The admin password for the database."
  default     = "Password1234!"
}

