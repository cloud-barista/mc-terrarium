# vpc-gcp.tf
resource "google_compute_network" "main" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.environment}-subnet"
  ip_cidr_range = "10.1.0.0/24"
  region        = "asia-northeast3"
  network       = google_compute_network.main.id
}

# GCP Firewall and Rules
resource "google_compute_firewall" "main" {
  name    = "${var.environment}-firewall"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
    ports    = ["33434-33534"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# GCP VM instance
resource "google_compute_instance" "main" {
  name         = "${var.environment}-vm"
  machine_type = "e2-micro"
  zone         = "asia-northeast3-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts" # Ubuntu 22.04 LTS
      size  = 20                                # GB
    }
  }

  network_interface {
    network    = google_compute_network.main.name
    subnetwork = google_compute_subnetwork.main.name

    access_config {
      // Automatically assign a public IP address to the instance
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.ssh.public_key_openssh}"
  }
}
