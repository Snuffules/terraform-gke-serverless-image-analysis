resource "google_container_cluster" "mongodb_cluster" {
  name       = "mongodb-cluster"
  location   = var.region
  network    = var.network
  subnetwork = var.subnetwork

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false 
    master_ipv4_cidr_block  = "10.0.1.0/28"    #master node to communicate with cluster 
  }
  ## You could specify the pod IP range here
/*   ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.100.0.0/14"
    services_ipv4_cidr_block = "10.32.0.0/20"
  } */

  ## Other configurations 
#  remove_default_node_pool = true
  ##########################################
  # TEST: If you used private_endpoint = true
  ##########################################
/*   master_authorized_networks_config {
    cidr_blocks {
      display_name = "vpc_access_connector"
      cidr_block   = "10.8.0.0/28"
    }
    cidr_blocks {
      display_name = "vpc"
      cidr_block   = "10.0.0.0/24"
    }
    cidr_blocks {
      display_name = "vpc_access"
      cidr_block   = "10.0.1.0/28"
    }   
  } */
  ######################################## 
  initial_node_count = 1
  node_config {
    tags = ["mongodb-server"]    
    preemptible  = false      
    disk_size_gb  = 10
    machine_type  = "e2-medium"    
    disk_type     = "pd-standard"
    metadata      = {
      disable-legacy-endpoints= true
    }
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform",
       "https://www.googleapis.com/auth/logging.write",
       "https://www.googleapis.com/auth/monitoring"
    ]
    service_account = var.service_account_compute
  }
  master_auth {
  client_certificate_config {
    issue_client_certificate = false
    }
  }
    # Set deletion protection to false
  deletion_protection = false  
}

# Create a new Kubernetes namespace for your MongoDB server
resource "kubernetes_namespace" "mongodb" {
  depends_on = [google_container_cluster.mongodb_cluster]    

  metadata {
    name = "mongodb"
  }
}
