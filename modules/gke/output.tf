output "google_container_cluster_composer_cluster" {
  value = google_container_cluster.mongodb_cluster
}

output "kubernetes_namespace_mongodb" {
  value = kubernetes_namespace.mongodb.metadata[0].name
}

output "google_container_cluster_mongodb_cluster_ipv4_cidr" {
  value = google_container_cluster.mongodb_cluster.private_cluster_config[0].master_ipv4_cidr_block
}