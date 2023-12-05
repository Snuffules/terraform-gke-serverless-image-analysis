 # Firewall rules for MongoDB subnet
resource "google_compute_firewall" "mongodb_firewall" {
  name    = "allow-mongodb"
  network = google_compute_network.mongodb_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }
  source_ranges = ["10.8.0.0/28", "10.0.0.0/24", "10.0.1.0/28", var.load_balancer_ip] #"10.68.0.42"] # vpc, subnet, load balancer and gke master ipv4 cidr range 
}
