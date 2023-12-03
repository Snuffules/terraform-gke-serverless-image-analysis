resource "kubernetes_service" "mongo_lb_svc" {
  metadata {
    name = "mongo-lb-svc"
    namespace = var.nms   
    labels = {
      app     = "mongodb-app"
      release = var.release
    }

    annotations = {
      "service.alpha.kubernetes.io/tolerate-unready-endpoints" = "true"
    }     
  }
  spec {
    port {
      name        = "mongodb"
      port        = 27017 # The service is exposed on this port within the cluster
      target_port = 27017 # The service forwards traffic to this port on the Pod
# NodePort
#      node_port = 30001  #Optional        
      protocol    = "TCP"
    }
 

    selector = {
      app     = "mongodb-app"
      release = var.release
    }

    type                        = "LoadBalancer"
    cluster_ip  = "10.68.0.42"  # Predefined available range: The range of valid IPs is 10.68.0.0/20 
#    cluster_ip  = "None"  # This makes the service headless

    # NodePort has limitation to 30000-32767 ports only. Ingress will expose to public internet. LoadBalancer is used as we use created public address for mongo uri connection string.
    # Therefore, LoadBalancer should be best choice to expose over the network. It is included in Firewall for additional protection and allowing only 27017 port.
    publish_not_ready_addresses = true
  }
} 

