resource "google_compute_firewall" "firewall_1" {
  name    = "firewall-1"
  network = data.google_compute_network.injected_vpc_network.name

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