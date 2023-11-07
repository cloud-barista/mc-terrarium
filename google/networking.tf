
# Create a VPC network
resource "google_compute_network" "vpc_network" {
  name                    = "my-vpc-network"
  auto_create_subnetworks = "false" # Disable auto create subnetwork
}

# Create the first subnet
resource "google_compute_subnetwork" "subnet1" {
  name          = "my-subnet-1"
  ip_cidr_range = "192.168.0.0/24"
  network       = google_compute_network.vpc_network.self_link
  region        = "asia-northeast3"
}

# Create the second subnet
resource "google_compute_subnetwork" "subnet2" {
  name          = "my-subnet-2"
  ip_cidr_range = "192.168.1.0/24"
  network       = google_compute_network.vpc_network.self_link
  region        = "asia-northeast3"
}


# Create a Cloud Router
resource "google_compute_router" "my_router" {
  name    = "my-router"
  network = google_compute_network.vpc_network.name
  asn     = 65530 # Set the ASN number for the Cloud Router
}

# Create a Cloud VPN Gateway
resource "google_compute_vpn_gateway" "my_vpn_gateway" {
  name    = "my-vpn-gateway"
  network = google_compute_network.vpc_network.name
}
