variable "resource_group_name" {
  description = "The name of the existing Azure Resource Group where AKS will be deployed."
  type        = string
  # No default - must be provided
}

variable "location" {
  description = "The Azure region to deploy AKS to."
  type        = string
  default     = "Korea Central" # Korea Central region
}

variable "cluster_name" {
  description = "The name for the AKS cluster."
  type        = string
  default     = "my-first-aks-cluster"
}

variable "dns_prefix" {
  description = "A unique DNS prefix for the AKS cluster."
  type        = string
  default     = "myaks-cluster-dns" # Must be unique within the region
}

# Network configuration variables (required for existing infrastructure)
variable "vnet_resource_group_name" {
  description = "The name of the resource group containing the existing virtual network."
  type        = string
  # No default - must be provided when using existing VNet
}

variable "vnet_name" {
  description = "The name of the existing virtual network to use for AKS."
  type        = string
  # No default - must be provided
}

variable "subnet_name" {
  description = "The name of the existing subnet to use for AKS nodes."
  type        = string
  # No default - must be provided
}

# Optional: Kubernetes service networking configuration
variable "service_cidr" {
  description = "The CIDR range for Kubernetes services. Only used when creating a new network."
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "The IP address for the Kubernetes DNS service. Must be within service_cidr range."
  type        = string
  default     = "10.1.0.10"
}
