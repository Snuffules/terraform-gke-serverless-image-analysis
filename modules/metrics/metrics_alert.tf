/* resource "google_monitoring_alert_policy" "pvc_usage_alert" {
  display_name = "High PVC Usage Alert"
  combiner     = "OR"
  conditions {
    display_name = "PVC Usage above threshold"
    condition_threshold {
      filter     = "metric.type=\"kubelet_volume_stats_used_bytes\" AND resource.type=\"k8s_cluster\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.8
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  notification_channels = [google_monitoring_notification_channel.email.id]
  user_labels = {
      app     = "mongodb-pvc-alert"
  }  
} */

/* resource "google_monitoring_alert_policy" "pvc_usage_alert" {
  display_name = "High PVC Usage Alert"

  conditions {
    display_name = "PVC Usage Threshold"

    condition_threshold {
      filter = "metric.type=\"kubelet_volume_stats_used_bytes\" resource.type=\"k8s_pod\""
      duration = "300s" // Duration over which the condition is evaluated

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }

      comparison = "COMPARISON_GT"
      threshold_value = 80 // Adjust the threshold as needed

      trigger {
        count = 1
      }
    }
  }

  combiner = "AND"

  notification_channels = [google_monitoring_notification_channel.email.id]
} */


// Alert Policy for pod_volume_utilization
resource "google_monitoring_alert_policy" "pod_volume_utilization_alert" {
  display_name = "High Pod Volume Utilization Alert"

  conditions {
    display_name = "Pod Volume Utilization over 80%"

    condition_threshold {
      filter = "metric.type=\"custom.googleapis.com/pod/volume/utilization\" AND resource.type=\"k8s_pod\""
      duration = "60s" // Duration over which the condition is evaluated
      
      // Define the threshold value and comparison type
      comparison  = "COMPARISON_GT" // Greater than
      threshold_value = 300000000000 // 300Gb

      aggregations {
        alignment_period   = "60s" // Period over which to aggregate the data
        per_series_aligner = "ALIGN_MEAN" // or choose ALIGN_MAX, ALIGN_MIN, etc.
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

  // Add additional configurations such as user_labels if needed
}

// Remember to replace the filter with the correct metric and labels to match your environment




resource "google_monitoring_notification_channel" "email" {
  type = "email"
  labels = {
    email_address = "snuff.mcloud@gmail.com"
  }
}

resource "google_project_iam_member" "monitoring_editor" {
  project = var.project_id // Replace with your actual project ID
  role    = "roles/monitoring.editor"
  member  = "user:snuff.mcloud@gmail.com" // Replace with the actual email
}

/* pod/volume/total_bytes GA
Volume capacity
GAUGE, INT64, By
k8s_pod	Total number of disk bytes available to the pod. Sampled every 60 seconds. After sampling, data is not visible for up to 120 seconds.
volume_name: The name of the volume (e.g. `/dev/sda1`).
persistentvolumeclaim_name: The name of the referenced Persistent Volume Claim.
persistentvolumeclaim_namespace: The namespace of the referenced Persistent Volume Claim.
pod/volume/used_bytes GA
Volume usage
GAUGE, INT64, By
k8s_pod	Number of disk bytes used by the pod. Sampled every 60 seconds.
volume_name: The name of the volume (e.g. `/dev/sda1`).
persistentvolumeclaim_name: The name of the referenced Persistent Volume Claim.
persistentvolumeclaim_namespace: The namespace of the referenced Persistent Volume Claim.
pod/volume/utilization GA
Volume utilization
GAUGE, DOUBLE, 1
k8s_pod	The fraction of the volume that is currently being used by the instance. This value cannot be greater than 1 as usage cannot exceed the total available volume space. Sampled every 60 seconds. After sampling, data is not visible for up to 120 seconds.
volume_name: The name of the volume (e.g. `/dev/sda1`).
persistentvolumeclaim_name: The name of the referenced Persistent Volume Claim.
persistentvolumeclaim_namespace: The namespace of the referenced Persistent Volume Claim. */

/* Name
Log bytes
Description
Number of bytes in ingested log entries. Excluded logs are not counted.
Metric
logging.googleapis.com/byte_count
Resource types
Unit
By
Kind
DELTA
Value type
INT64 */