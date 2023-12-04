module "storage_pvc" {
  source = "./modules/storage_pvc"
  depends_on = [module.gke]
}

module "vpc" {
  source = "./modules/vpc"
  load_balancer_ip = module.mongodb.load_balancer_ip  
}

module "pubsub" {
  source = "./modules/pubsub"
}

module "img_analysis" {
  source = "./modules/zip_function/img_analysis"
  load_balancer_ip = module.mongodb.load_balancer_ip
  mongonetwork = module.vpc.google_compute_network_vpc_network_name
  depends_on = [module.vpc]
}

resource "time_sleep" "wait_60_seconds" {
  create_duration = "60s"
}

module "img_processing" {
  source = "./modules/zip_function/img_processing"
  pubstopic = module.pubsub.google_pubsub_topic_my_topic
  depends_on = [time_sleep.wait_60_seconds]   #Needed for pubsub topic propagation 
}

module "docker" {
  source = "./modules/docker"
}

module "gke" {
  source = "./modules/gke"
  network    = module.vpc.google_compute_network_vpc_network_name
  subnetwork = module.vpc.google_compute_subnetwork_subnet_name
  cdr        = module.vpc.google_compute_subnetwork_subnet_name_ip_cidr_range
}

module "mongodb" {
  source = "./modules/mongodb"
  nms = module.gke.kubernetes_namespace_mongodb
  depends_on = [module.gke, module.storage_pvc]
}

module "test_images" {
  image_handler = module.img_analysis.google_storage_bucket_image_handler_trigger
  source = "./modules/test_images"
  depends_on = [module.img_analysis, time_sleep.wait_60_seconds] #To ensure function is started and ready
}

module "metrics" {
  source = "./modules/metrics"
  depends_on = [module.img_analysis] #To ensure metric descriptor is created and started is started. Couild take up to 10 mins
}



