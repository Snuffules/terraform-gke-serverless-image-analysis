data google_client_config "current" {}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${module.gke.google_container_cluster_composer_cluster.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(module.gke.google_container_cluster_composer_cluster.master_auth[0].cluster_ca_certificate)
}
