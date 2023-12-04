resource "google_compute_disk" "mongodb_disk" {
  name  = "mongodb-disk"
  type  = "pd-standard"  // or "pd-ssd" for SSD
  zone  = "europe-west1-b"  // change this to your desired zone
  size  = 10  // size in GB
}

resource "kubernetes_persistent_volume" "mongodb_pv" {
  metadata {
    name = "mongodb-volume"
  }
  spec {
    capacity = {
      storage = "24Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      gce_persistent_disk {
        pd_name = "mongodb-disk"
      }
    }
  }
}
