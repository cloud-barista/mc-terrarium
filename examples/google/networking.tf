
# Create a VPC network
resource "google_compute_network" "my_vpc_network" {
  name                    = "my-vpc-network"
  auto_create_subnetworks = "false" # Disable auto create subnetwork
}

# Create the first subnet
resource "google_compute_subnetwork" "subnet1" {
  name          = "my-subnet-1"
  ip_cidr_range = "192.168.0.0/24"
  network       = google_compute_network.my_vpc_network.self_link
  region        = "asia-northeast3"
}

# Create the second subnet
resource "google_compute_subnetwork" "subnet2" {
  name          = "my-subnet-2"
  ip_cidr_range = "192.168.1.0/24"
  network       = google_compute_network.my_vpc_network.self_link
  region        = "asia-northeast3"
}

########################################################
# Create a Cloud Router
# Reference: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router
resource "google_compute_router" "my_router" {
  name = "my-router"
  # description = "my cloud router"  
  network = google_compute_network.my_vpc_network.name
  region  = "asia-northeast3"

  bgp {
    asn               = 65530
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    # [NOTE] This may specify a single IP address. 
    # advertised_ip_ranges {
    #   range = "1.2.3.4"
    # }

    # [NOTE] This may specify a CIDR range.
    # Q. Exact CIDR range or rough CIDR range?
    # Q. Can I skip to assign a CIDR range?
    # advertised_ip_ranges {
    #   range = "192.168.1.0/24"
    # }
  }
}

########################################################

# # Q. Is this VPC network?
# resource "google_compute_network" "foobar" {
#   name                    = "my-network"
#   auto_create_subnetworks = false
# }


# Create a Cloud VPN Gateway
resource "google_compute_vpn_gateway" "my_vpn_gateway" {
  name    = "my-vpn-gateway"
  network = google_compute_network.my_vpc_network.name
  region  = "asia-northeast3"
}


# Q. How can I get 2 public IP addresses for VPN gateway?
