resource "google_compute_resource_policy" "daily" {
  name   = "daily-snapshot-policy"
  region = "europe-west1"

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "mongodb_disk_policy" {
  name = google_compute_resource_policy.daily.name
  disk = google_compute_disk.mongodb_disk.name
  zone = "europe-west1-b"
}


data "google_iam_policy" "admin" {
  binding {
    role = "roles/viewer"
    members = [
      "serviceAccount:583337782650-compute@developer.gserviceaccount.com",
    ]
  }
}

