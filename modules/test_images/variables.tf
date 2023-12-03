variable "project_id" {
    default = "serverless-violence-score"
}

variable "region" {
    default = "europe-west1"
}

variable "service_account" {
    default = "491450312439-compute@developer.gserviceaccount.com"
}

variable "image_handler" {
  description = "The name of the bucket to store test images"
  type        = string
}


