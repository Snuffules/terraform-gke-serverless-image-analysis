output "load_balancer_ip" {
  value = kubernetes_service.mongo_lb_svc.status[0].load_balancer[0].ingress[0].ip
}

output "k8s_endpoint_ip" {
   value = kubernetes_service.mongo_lb_svc.spec[0].cluster_ip
   description = "IP address of the Kubernetes Endpoint"
}
