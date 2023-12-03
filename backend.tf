####################################################
# Storing remotely tfstate / Uncomment after first apply
####################################################

/* terraform {
 backend "gcs" {
   bucket  = "tfstate"
   prefix  = "terraform/state"
 }
} */