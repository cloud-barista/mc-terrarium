# outputs.tf
output "testbed_info" {
  value = {
    vpc_name    = google_compute_network.main.name
    subnet_name = google_compute_subnetwork.main.name
    subnet_cidr = google_compute_subnetwork.main.ip_cidr_range
    project_id  = jsondecode(file("credential-gcp.json")).project_id
    private_ip  = google_compute_instance.main.network_interface[0].network_ip
  }
}

output "ssh_info" {
  sensitive = true
  value = {
    public_ip  = google_compute_instance.main.network_interface[0].access_config[0].nat_ip
    private_ip = google_compute_instance.main.network_interface[0].network_ip
    user       = "ubuntu"
    command    = "ssh -i private_key.pem ubuntu@${google_compute_instance.main.network_interface[0].access_config[0].nat_ip}"
  }
}
