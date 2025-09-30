# DCS (DevStack Cloud Service) Connection Variables
# These are handled by environment variables:
# OS_USERNAME, OS_PROJECT_NAME, OS_PASSWORD, OS_AUTH_URL, OS_REGION_NAME
# Load them using: source ../../secrets/load-openstack-cred-env.sh

# Network Configuration
variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "192.168.100.0/26"
}

# Compute Configuration
variable "instance_flavor" {
  description = "Flavor for the compute instance"
  type        = string
  default     = "m1.medium"
}

variable "instance_image" {
  description = "Image name for the compute instance"
  type        = string
  default     = "ubuntu-22.04"
}

# Resource Naming
variable "name_prefix" {
  description = "Prefix for all resource names to ensure clear identification in OpenStack Dashboard"
  type        = string
  default     = "tofu-dcs"
}

# External Network
variable "external_network_name" {
  description = "Name of the external network for floating IPs"
  type        = string
  default     = "public"
}
