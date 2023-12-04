## Alert Policy for pod_volume_utilization
resource "google_monitoring_alert_policy" "pod_volume_utilization_alert" {
  display_name = "High Pod Volume Utilization Alert"

  conditions {
    display_name = "Pod Volume Utilization over 80%"

    condition_threshold {
      filter = "metric.type=\"kubernetes.io/pod/volume/total_bytes\" AND resource.type=\"k8s_pod\""
      duration = "60s" # Duration over which the condition is evaluated

      ## Define the threshold value and comparison type
      comparison  = "COMPARISON_GT" # Greater than
      threshold_value = 20000000000 # 20Gb

      aggregations {
        alignment_period   = "60s" # Period over which to aggregate the data
        per_series_aligner = "ALIGN_MEAN"
        #Replace ALIGN_MEAN with the aligner that best fits your monitoring needs. 
        #The choice of aligner depends on how you want to interpret the utilization data. 
        #For instance, ALIGN_MEAN will give you the average utilization over the specified period, while ALIGN_MAX will give you the maximum utilization.
      }
    }
  }
  notification_channels = [google_monitoring_notification_channel.email.id]
  // Setup notification channels as needed
  combiner = "OR" // How conditions are combined to determine if an incident should be opened

  documentation {
    content   = "Pod volume utilization is over 80%, indicating high usage."
    mime_type = "text/markdown"
  }
  user_labels = {
      app     = "mongodb-pvc-alert"
  }
}

resource "google_monitoring_notification_channel" "email" {
  type = "email"
  labels = {
    email_address = "snuff.mcloud@gmail.com"
  }
}

resource "google_project_iam_member" "monitoring_editor" {
  project = var.project_id 
  role    = "roles/monitoring.editor"
  member  = "user:snuff.mcloud@gmail.com" 
}