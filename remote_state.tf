##########################
# Storing remotely tfstate
##########################
#################################################################
# Server-Side encryption is enabled by default using: 
# Google Cloud Storage bucket using the default encryption (GMEK)
#################################################################

resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "tfstate" {
  name          = "${random_id.bucket_prefix.hex}-bucket-tfstate"
  force_destroy = false
  location      = "EU"
  storage_class = "STANDARD"
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