resource "google_container_cluster" "mongodb_cluster" {
  name       = "mongodb-cluster"
  location   = var.region
  network    = var.network
  subnetwork = var.subnetwork

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false 
    #################################################################################################
#    enable_private_endpoint = true    
     # TEST # Possible if we setup VPN or Bastion system, but this will go outside serveless solution
    ##################################################################################################
    master_ipv4_cidr_block  = "10.0.1.0/28"    #master node to communicate with cluster 
  }
  ## Specify the pod IP range here
/*   ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.100.0.0/14"
    services_ipv4_cidr_block = "10.32.0.0/20"
  } */

  ## Other configurations 
#  remove_default_node_pool = true
  ##########################################
  # TEST
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

/* enable_private_nodes: 

When set to true, this option ensures that the nodes of the cluster do not have public IP addresses. 
This means that the nodes are only accessible from within the Google Cloud network.
 This setting is often used to enhance the security of the cluster by ensuring that the nodes are not accessible from the public internet.

enable_private_endpoint: 

This option, when set to true, makes the Kubernetes API server accessible only from within the Google Cloud network.
 When set to false, the API server is accessible from the public internet, although it can still be secured and limited using authorized networks or other security mechanisms.

In this case, with enable_private_nodes set to true and enable_private_endpoint set to false,
 you have a configuration where the nodes of your GKE cluster are only accessible within the Google Cloud network, 
 but the Kubernetes API server is accessible from the public internet. 
 This setup provides a balance between protecting the nodes from direct public access while still allowing easy management
  of the cluster through the API server from outside the Google Cloud network.

This configuration is common and recommended when you need external access to the Kubernetes API server 
(like managing the cluster from a CI/CD pipeline outside Google Cloud) but still want to keep the workloads running on the nodes protected from direct public access.
 */
