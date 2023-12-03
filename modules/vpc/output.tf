output "google_compute_network_vpc_network_name" {
  value = google_compute_network.mongodb_network.self_link
}

output "google_compute_subnetwork_subnet_name" {
  value = google_compute_subnetwork.mongodb_subnet.self_link
}

output "google_compute_subnetwork_subnet_name_ip_cidr_range" {
  value = google_compute_subnetwork.mongodb_subnet.ip_cidr_range
}