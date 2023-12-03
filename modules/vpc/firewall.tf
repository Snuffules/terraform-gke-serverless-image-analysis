 # Firewall rules for MongoDB subnet
resource "google_compute_firewall" "mongodb_firewall" {
  name    = "allow-mongodb"
  network = google_compute_network.mongodb_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }
/*   allow {
    protocol = "tcp"
    ports    = ["443"] # For k8s API Accces
  } */
  source_ranges = ["10.8.0.0/28", "10.0.0.0/24", "10.0.1.0/28", var.load_balancer_ip] #"10.68.0.42"] #, var.k8s_ep ] # vpc, k8s endpoint and gke master ipv4 cidr range 
}