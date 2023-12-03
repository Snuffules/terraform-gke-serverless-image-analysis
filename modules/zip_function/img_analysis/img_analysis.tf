# Trigger bucket
resource "google_storage_bucket" "image_handler_trigger" {
  name          = "image_handler_tr"  
  location      = "europe-west1"
  force_destroy = true
  project = var.project_id
  uniform_bucket_level_access = true    
  public_access_prevention = "enforced" 

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  cors {
    origin          = []#["http://image-store.com"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
# Enable version control  
  versioning {
    enabled = true
  }
# Enable backup lifecycle
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }

    condition {
      age                   = 30
      with_state            = "ARCHIVED"
    }
  }  
}

# To store function on cloud storage
resource "google_storage_bucket" "image_handler_function" {
  name          = "image_handler_func"  
  location      = "europe-west1"
  force_destroy = true
  project = var.project_id
  uniform_bucket_level_access = true    
 #  public_access_prevention = "enforced" 

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  cors {
    origin          = []#["http://image-store.com"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
# Enable version control  
  versioning {
    enabled = true
  }
# Enable backup lifecycle
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }

    condition {
      age                   = 30
      with_state            = "ARCHIVED"
    }
  }  
}

###########################################################
# Archiving and storing function on cloud storagea as .zip
###########################################################
data "archive_file" "img_analysis" {
  type        = "zip"
  output_path = "/tmp/function-source-img_analysis.zip"
  source_dir  = "modules/function/img_analysis"
}
resource "google_storage_bucket_object" "img-analysis-object" {
  name   = "function-source-img_analysis.zip"
  bucket = google_storage_bucket.image_handler_function.name
  source = data.archive_file.img_analysis.output_path # Add path to the zipped function source code
}

####################################################################################################
# Cloud function v1 (VPC Access can be used only with v1) | Trigger is upload event in cloud storage
####################################################################################################

resource "google_cloudfunctions_function" "img_analysis" {
  name        = var.name
  description = var.description
  runtime     = var.runtime
  region      = var.region
  project     = var.project_id

  available_memory_mb   = var.memory
  timeout               = var.timeout_seconds
  entry_point           = var.entry_point
  service_account_email = var.service_account
  labels                = var.labels

  environment_variables = {
    BUILD_CONFIG_TEST     = var.build_test
    MONGODB_URI           = "mongodb://mongouser:mongopassword@${var.load_balancer_ip}:27017/test?authSource=admin&authMechanism=SCRAM-SHA-256"
#    MONGODB_URI           = var.mongodb_uri    #Not used for now as I import another var into mongo uri (cannot use var in var)
    PUBSUB_TOPIC          = var.pubsub_topic
    GOOGLE_CLOUD_PROJECT  = var.google_cloud_project
  }

  source_archive_bucket = google_storage_bucket.image_handler_function.name
  source_archive_object = google_storage_bucket_object.img-analysis-object.name

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.image_handler_trigger.name
  }
 ##################################################### 
 # VPC Connector settings 
 # Use the fully qualified name for the VPC connector
 #####################################################
  vpc_connector = "projects/${var.project_id}/locations/${var.region}/connectors/${google_vpc_access_connector.serverless_connector.name}"
  max_instances = var.max_instance_count

  vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"
}

