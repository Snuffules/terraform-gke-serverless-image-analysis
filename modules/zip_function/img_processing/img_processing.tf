/* resource "random_id" "img_processing" {
  byte_length = 8
}
 */

# Trigger storage
resource "google_storage_bucket" "safe_storage_trigger" {
/*   name          = "${random_id.img_processing.hex}-safe-storage" */
  name          = "safe_storage_tr"  
  location      = "europe-west1"
  force_destroy = true
  project = var.project_id
  uniform_bucket_level_access = true  
/*   public_access_prevention = "enforced"   */

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
resource "google_storage_bucket" "safe_storage_function" {
/*   name          = "${random_id.img_processing.hex}-safe-storage" */
  name          = "safe_storage_func"  
  location      = "europe-west1"
  force_destroy = true
  project = var.project_id
  uniform_bucket_level_access = true  
/*   public_access_prevention = "enforced"   */

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

data "google_storage_project_service_account" "default" {
}

resource "google_project_iam_member" "gcs_pubsub_publishing" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.default.email_address}"
}

# Permissions on the service account used by the function and Eventarc trigger
resource "google_project_iam_member" "invoking" {
  project    = var.project_id
  role       = "roles/run.invoker"
  member     = "serviceAccount:${var.service_account}"
  depends_on = [google_project_iam_member.gcs_pubsub_publishing]
}

resource "google_project_iam_member" "event_receiving" {
  project    = var.project_id
  role       = "roles/eventarc.eventReceiver"
  member     = "serviceAccount:${var.service_account}"
  depends_on = [google_project_iam_member.invoking]
}

resource "google_project_iam_member" "artifactregistry_reader" {
  project    = var.project_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.service_account}"
  depends_on = [google_project_iam_member.event_receiving]
}

################
# Missing roles
################

resource "google_project_iam_member" "connectors_admin" {
  project    = var.project_id
  role       = "roles/connectors.admin"
  member     = "serviceAccount:${var.service_account}"
  depends_on = [google_project_iam_member.event_receiving]
}

resource "google_project_iam_member" "secretmanager_viewer" {
  project    = var.project_id
  role       = "roles/secretmanager.viewer"
  member     = "serviceAccount:${var.service_account}"
  depends_on = [google_project_iam_member.event_receiving]
}

resource "google_project_iam_member" "secretmanager_secretAccessor" {
  project    = var.project_id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${var.service_account}"
  depends_on = [google_project_iam_member.event_receiving]
}

resource "google_project_iam_member" "storage_admin" {
  project    = var.project_id
  role       = "roles/storage.admin"
  member     = "serviceAccount:${var.service_account}"
  depends_on = [google_project_iam_member.event_receiving]
}

###########################################################

data "archive_file" "img_processing" {
  type        = "zip"
  output_path = "/tmp/function-source-img_processing.zip"
  source_dir  = "modules/function/img_processing"
}
resource "google_storage_bucket_object" "img-processing-object" {
  name   = "function-source-img_processing.zip"
  bucket = google_storage_bucket.safe_storage_function.name
  source = data.archive_file.img_processing.output_path # Add path to the zipped function source code
}

resource "google_cloudfunctions2_function" "img_processing" {
  name        = var.name
  location    = var.location
  description = var.description
  project     = var.project_id
  labels      = var.labels

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point
    environment_variables   = {
      BUILD_CONFIG_TEST     = var.build_test
      PUBSUB_TOPIC          = var.pubsub_topic
      GOOGLE_CLOUD_PROJECT  = var.project_id      
    }
    source {
      storage_source {
        bucket = google_storage_bucket.safe_storage_function.id
        object = google_storage_bucket_object.img-processing-object.name
      }
    }
  }

  service_config {
    min_instance_count             = var.min_instance_count
    max_instance_count             = var.max_instance_count
    timeout_seconds                = var.timeout_seconds
    ingress_settings               = var.ingress_settings
    service_account_email          = var.service_account
  }
################################################################################
#  official guidance from google for strorage trigger
################################################################################  

  event_trigger {
    trigger_region        = "europe-west1"
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    retry_policy          = "RETRY_POLICY_RETRY"
    service_account_email = var.service_account
    pubsub_topic          = "projects/${var.project_id}/topics/my-topic"
  }
  
}
