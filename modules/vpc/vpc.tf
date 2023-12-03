# VPC Network for MongoDB
resource "google_compute_network" "mongodb_network" {
  name                    = "mongodb-network"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Subnet for MongoDB
resource "google_compute_subnetwork" "mongodb_subnet" {
  name          = "mongodb-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.mongodb_network.self_link
  region        = var.region
  project       = var.project_id
  ###############################
  # TEST
  ###############################
#  private_ip_google_access = true  # Enable Private Google Access - TEST 
  ###################################################################### 
}