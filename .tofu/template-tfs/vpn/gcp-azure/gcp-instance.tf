
# Randomly select a zone
resource "random_shuffle" "gcp_zones_in_region" {
  input        = data.google_compute_zones.gcp_available_zones.names
  result_count = 1
}

# Create VM instance
resource "google_compute_instance" "vm_instance_1" {
  name         = "vm-instance-1-name"
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
    network = data.google_compute_network.injected_vpc_network.self_link
    subnetwork = data.google_compute_subnetwork.injected_vpc_subnetwork.self_link  
  }
}
