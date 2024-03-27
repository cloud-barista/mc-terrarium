resource "google_compute_firewall" "test_firewall" {
  name    = "tofu-gcp-firewall"
  network = google_compute_network.test_vpc_network.id
  
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