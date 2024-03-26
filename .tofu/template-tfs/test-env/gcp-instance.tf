// Fetch the available zones in the region
data "google_compute_zones" "gcp_available_zones" {
  region = var.gcp-region 
}

# Randomly select a zone
resource "random_shuffle" "gcp_zones_in_region" {
  input        = data.google_compute_zones.gcp_available_zones.names
  result_count = 1
}

# Define a VM instance
resource "google_compute_instance" "test_vm_instance" {
  name         = "tofu-gcp-vm-instance"
  machine_type = "f1-micro"

  zone = random_shuffle.gcp_zones_in_region.result[0] // Dynamically selected zone

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
    network = google_compute_network.test_vpc_network.self_link
    subnetwork = google_compute_subnetwork.test_subnetwork_1.self_link
  }
}