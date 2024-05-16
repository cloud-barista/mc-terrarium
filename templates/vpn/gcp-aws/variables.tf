variable "resource-group-id" {
  type        = string
  description = "Unique ID to distinguish and manage infrastructure."

  validation {
    condition     = var.resource-group-id != ""
    error_message = "The resource group ID must be set"
  }
}

#######################################################################
# Amazon Web Services (AWS)
variable "aws-region" {
  type        = string
  description = "A region in AWS."
  default     = "ap-northeast-2"
  # AWS regions mapping list:
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html
}

variable "aws-vpc-id" {
  type        = string
  description = "The VPC ID in AWS."
}

variable "aws-subnet-id" {
  type        = string
  description = "The subnet ID in AWS."
}

#######################################################################
# Google Cloud Platform (GCP)
variable "gcp-region" {
  type        = string
  description = "A region in GCP"
  default     = "asia-northeast3"  
}

variable "gcp-vpc-network-name" {
  type        = string
  description = "The VPC network name in GCP"
  default     = "terrarium-vpc01"
}

# variable "gcp-subnetwork-name" {
#   type        = string
#   description = "The subnetwork name in GCP"
# }

variable "gcp-bgp-asn" {
  type        = string
  description = "Autonomous System Number(ASN) for Border Gateway Protocol(BGP) in GCP"
  default     = "65530"
}



# output "my-imported-gcp-vpc-id" {
#   value = data.google_compute_network.my-imported-gcp-vpc-network.id
# }

# output "my-imported-gcp-vpc-self-link" {
#   value = data.google_compute_network.my-imported-gcp-vpc-network.self_link
# }

# Unused
# output "my-imported-gcp-vpc-subnetwork-id" {
#   value = data.google_compute_subnetwork.my-imported-gcp-vpc-subnetwork.id
# }

# output "my-imported-gcp-vpc-subnetwork-self-link" {
#   value = data.google_compute_subnetwork.my-imported-gcp-vpc-subnetwork.self_link
# }
