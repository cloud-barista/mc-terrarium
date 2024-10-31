
# Randomly select a zone
resource "random_shuffle" "my-gcp-zones" {
  input        = data.google_compute_zones.my-gcp-available-zones.names
  result_count = 1
}

# Create VM instance
resource "google_compute_instance" "my-gcp-vm-instance" {
  name         = "my-gcp-vm-instance-name"
  machine_type = "f1-micro"
  zone         = random_shuffle.my-gcp-zones.result[0] # Dynamically selected zone


  boot_disk {
    auto_delete = true
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20240126"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    network    = google_compute_network.my-gcp-vpc-network.self_link
    subnetwork = google_compute_subnetwork.my-gcp-subnet-2.self_link
  }
}
