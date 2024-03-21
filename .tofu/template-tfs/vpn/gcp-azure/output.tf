output "injected_vpc_network_id" {
  value = data.google_compute_network.injected_vpc_network.id
}

output "injected_vpc_network_self_link" {
  value = data.google_compute_network.injected_vpc_network.self_link
}

output "injected_vpc_subnetwork_self_link" {
  value = data.google_compute_subnetwork.injected_vpc_subnetwork.self_link
}