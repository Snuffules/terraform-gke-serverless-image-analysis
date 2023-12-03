locals {
  docker_image = "eu.gcr.io/serverless-violence-score/mongo:latest"
}  

locals {
  docker_file = "${path.module}.dockerfile"
}  

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.13"  # Specify the version you want to use
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
  registry_auth {
    address = "eu.gcr.io"
    config_file = pathexpand("${path.module}/config.json")  
 }
}

resource "null_resource" "docker_build" {

  triggers = {
  always_run = timestamp()

}

  provisioner "local-exec" {
  working_dir = path.module
  command     = "docker build -t ${local.docker_file} ./ && docker push ${local.docker_image}"
 }
}
