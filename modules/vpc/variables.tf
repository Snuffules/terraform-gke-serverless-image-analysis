variable "project_id" {
    default = "serverless-violence-score"
}

variable "region" {
    default = "europe-west1"
}

variable "service_perimeter_name" {
  description = "The name of the service perimeter"
  default = "my_vpc_service_perimeter"
}

variable "resources" {
  description = "The GCP resources that are part of this perimeter"
  type        = list(string)
  default = ["projects/serverless-violence-score"]
}

variable "restricted_services" {
  description = "List of Google services that are restricted by this service perimeter"
  type        = list(string)
  default = [
    "container.googleapis.com",    # GKE (Google Kubernetes Engine)
    "cloudfunctions.googleapis.com", # Cloud Functions
    "pubsub.googleapis.com",       # Pub/Sub
    "storage.googleapis.com",      # Google Cloud Storage
  ]
}

/* variable "k8s_ep" {
#  type        = number    
}
 */

variable "load_balancer_ip" {
}
