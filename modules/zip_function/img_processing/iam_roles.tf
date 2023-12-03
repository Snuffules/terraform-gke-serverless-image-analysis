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