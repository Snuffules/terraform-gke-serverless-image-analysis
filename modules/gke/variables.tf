variable "network" {
  description = "The name of the network"
  type        = string
}

variable "subnetwork" {
  description = "The name of the subnetwork"
  type        = string
}

variable "cdr" {
  description = "The name of the subnetwork"
  type        = string
}

variable "project_id" {
    default = "serverless-violence-score"
}

variable "region" {
    default = "europe-west1"
}

variable "service_account_compute" {
    default = "583337782650-compute@developer.gserviceaccount.com"
}