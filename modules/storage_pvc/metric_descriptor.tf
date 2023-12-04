// Metric Descriptor for pod/volume/total_bytes
resource "google_monitoring_metric_descriptor" "pod_volume_total_bytes" {
  display_name = "PVC Volume Total Bytes"
  description = "PVC Total Bytes"    
  type        = "custom.googleapis.com/pod/volume/total_bytes"
  metric_kind = "GAUGE"
  value_type  = "INT64"

  labels {
    key         = "volume_name"
    value_type  = "STRING"
    description = "mongodb-volume"
  }

  labels {
    key         = "persistentvolumeclaim_name"
    value_type  = "STRING"
    description = "mongodb-volume"
  }

  labels {
    key         = "persistentvolumeclaim_namespace"
    value_type  = "STRING"
    description = "mongodb"
  }
}

// Metric Descriptor for pod/volume/used_bytes
resource "google_monitoring_metric_descriptor" "pod_volume_used_bytes" {
  display_name = "PVC Volume Used Bytes"
  description = "PVC Used Bytes" 
  type        = "custom.googleapis.com/pod/volume/used_bytes"
  metric_kind = "GAUGE"
  value_type  = "INT64"

  // Repeat the labels as in the previous resource
}

// Metric Descriptor for pod/volume/utilization
resource "google_monitoring_metric_descriptor" "pod_volume_utilization" {
  display_name = "PVC Utilization above threshold"
  description = "PVC Usage"
  type        = "custom.googleapis.com/pod/volume/utilization"
  metric_kind = "GAUGE"
  value_type  = "DOUBLE"

  // Repeat the labels as in the previous resources
}

// You can then set up alert policies based on these metrics using the `google_monitoring_alert_policy` resource
