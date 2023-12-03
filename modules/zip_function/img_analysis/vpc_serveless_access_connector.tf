#############################################
# VPC Access Connector for the Cloud Function
#############################################
resource "google_vpc_access_connector" "serverless_connector" {
  name          = "serverless-connector"
  project       = var.project_id
  region        = var.region
  network       = var.mongonetwork
  ip_cidr_range = "10.8.0.0/28" 
  min_throughput = 200
  max_throughput = 300
}