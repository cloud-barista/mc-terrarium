resource "google_compute_firewall" "my-gcp-firewall" {
  name    = "my-gcp-firewall"
  # network = google_compute_network.my-gcp-vpc-network.name
  network = var.my-imported-gcp-vpc-id
  
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8080", "1000-2000"]
  }

  source_ranges = ["0.0.0.0/0"]

  # source_tags = ["web"]
}

# resource "google_compute_network" "default" {
#   name = "test-network"
# }