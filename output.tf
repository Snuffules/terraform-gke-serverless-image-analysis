output "connect_to_gke" {
  value = "gcloud container clusters get-credentials mongo-cluster --region europe-west1 --project serverless-violence-score"
}

output "connect_to_mongo" {
  value = "kubectl exec -ti mongodb-0 -n mongodb -- mongosh "
}

output "Refence_Images_to_Test_Serveless_Solution" {
  value = "modules/USE IMAGES TO TEST"
}

output "mongo_lb_ip" {
  value = module.mongodb.load_balancer_ip
}

output "mongo_ep_ip" {
  value = module.mongodb.k8s_endpoint_ip
}
