
variable "gcp-region" {
  type        = string
  description = "A region in GCP"
  default     = "asia-northeast3"  
}

# Create a VPC network
# Note - This is a VPC network. It doesn't seem to have a CIDR block.
resource "google_compute_network" "test_vpc_network" {
  name                    = "tofu-gcp-vpc"
  auto_create_subnetworks = "false" # Disable auto create subnetwork
}

# Create the first subnet
resource "google_compute_subnetwork" "test_gcp_subnet_0" {
  name          = "tofu-gcp-subnet-0"
  ip_cidr_range = "192.168.0.0/24"
  network       = google_compute_network.test_vpc_network.id
  region        = var.gcp-region
}

# Create the second subnet
resource "google_compute_subnetwork" "test_gcp_subnet_1" {
  name          = "tofu-gcp-subnet-1"
  ip_cidr_range = "192.168.1.0/24"
  network       = google_compute_network.test_vpc_network.id
  region        = var.gcp-region
}
