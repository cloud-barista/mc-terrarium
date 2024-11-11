variable "terrarium_id" {
  type        = string
  description = "Unique ID to distinguish and manage infrastructure."

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

variable "csp_subnet1_id" {
  type        = string
  description = "The subnet ID in AWS."
}

variable "csp_subnet2_id" {
  type        = string
  description = "The subnet ID in AWS."
}

# Required security group information
variable "db_engine_port" {
  type        = number
  description = "The port number for the database engine."
  default     = 3306
}

variable "ingress_cidr_block" {
  type        = string
  description = "The CIDR block for ingress traffic."
  default     = "0.0.0.0/0"
}

variable "egress_cidr_block" {
  type        = string
  description = "The CIDR block for egress traffic."
  default     = "0.0.0.0/0"
}

# Required database engine information
variable "db_instance_identifier" {
  type        = string
  description = "The identifier for the database."
  default     = "mydbinstance"
}

variable "db_engine_version" {
  type        = string
  description = "The version of the database engine."
  default     = "8.0.39"
}

variable "db_instance_class" {
  type        = string
  description = "The instance class for the database."
  default     = "db.t3.micro"
}

variable "db_admin_username" {
  type        = string
  description = "The admin username for the database."
  default     = "mydbadmin"
}

variable "db_admin_password" {
  type        = string
  description = "The admin password for the database."
  default     = "mysdbpass"
}

