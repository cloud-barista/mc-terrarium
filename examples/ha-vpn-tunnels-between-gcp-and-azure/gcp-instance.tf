resource "google_compute_instance" "my-gcp-vm-instance" {
  name         = "my-gcp-vm-instance"
  machine_type = "f1-micro"
  

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
    network = google_compute_network.my-gcp-vpc-network.self_link
    subnetwork = google_compute_subnetwork.my-gcp-subnet-2.self_link  
  }
}
