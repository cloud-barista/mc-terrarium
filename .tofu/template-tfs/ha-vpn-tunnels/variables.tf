
## AWS variables
variable "my-imported-aws-vpc-id" {
  type        = string
  description = "The id of the AWS VPC to use for the HA VPN tunnels."
}

variable "my-imported-aws-subnet-id" {
  type        = string
  description = "The id of the AWS subnet to use for the HA VPN tunnels."
}

## GCP variables
# VPC
variable "my-imported-gcp-vpc-name" {
  type        = string
  description = "The name of the GCP VPC to use for the HA VPN tunnels."
}

data "google_compute_network" "my-imported-gcp-vpc-network" {
  name = var.my-imported-gcp-vpc-name
}

output "my-imported-gcp-vpc-id" {
  value = data.google_compute_network.my-imported-gcp-vpc-network.id
}

output "my-imported-gcp-vpc-self-link" {
  value = data.google_compute_network.my-imported-gcp-vpc-network.self_link
}

# Subnet
variable "my-imported-gcp-subnet-name" {
  type        = string
  description = "The name of the GCP subnet to use for the HA VPN tunnels."
}

data "google_compute_subnetwork" "my-imported-gcp-vpc-subnetwork" {
  name = var.my-imported-gcp-subnet-name
}

# Unused
# output "my-imported-gcp-vpc-subnetwork-id" {
#   value = data.google_compute_subnetwork.my-imported-gcp-vpc-subnetwork.id
# }

output "my-imported-gcp-vpc-subnetwork-self-link" {
  value = data.google_compute_subnetwork.my-imported-gcp-vpc-subnetwork.self_link
}
