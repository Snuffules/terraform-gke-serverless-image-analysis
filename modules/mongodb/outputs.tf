output "load_balancer_ip" {
  value = kubernetes_service.mongo_lb_svc.status[0].load_balancer[0].ingress[0].ip
}

output "k8s_endpoint_ip" {
   value = kubernetes_service.mongo_lb_svc.spec[0].cluster_ip
#  value = [for s in kubernetes_endpoints.mongodb_ep.subset : s.address if length(s.address) > 0][0]
  description = "IP address of the Kubernetes Endpoint"
}
