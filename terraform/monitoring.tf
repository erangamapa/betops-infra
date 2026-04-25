resource "google_monitoring_notification_channel" "oncall" {
  display_name = "oncall email"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_alert_policy" "pubsub_oldest_unacked" {
  display_name = "Pub/Sub oldest unacked message age"
  combiner     = "OR"

  conditions {
    display_name = "Oldest unacked above 5 minutes"

    condition_threshold {
      filter          = "resource.type = \"pubsub_subscription\" AND metric.type = \"pubsub.googleapis.com/subscription/oldest_unacked_message_age\""
      comparison      = "COMPARISON_GT"
      threshold_value = 300
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.oncall.id]
}

resource "google_monitoring_alert_policy" "dead_letter_backlog" {
  display_name = "Dead letter queue has messages"
  combiner     = "OR"

  conditions {
    display_name = "DLQ inspect subscription not empty"

    condition_threshold {
      filter          = "resource.type = \"pubsub_subscription\" AND metric.type = \"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.label.subscription_id = monitoring.regex.full_match(\".*-dlq-inspect\")"
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.oncall.id]
}

resource "google_monitoring_alert_policy" "tasks_queue_depth" {
  display_name = "Cloud Tasks placement queue depth"
  combiner     = "OR"

  conditions {
    display_name = "Queue depth above 500"

    condition_threshold {
      filter          = "resource.type = \"cloud_tasks_queue\" AND metric.type = \"cloudtasks.googleapis.com/queue/depth\" AND resource.label.queue_id = \"${google_cloud_tasks_queue.placement_dispatch.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 500
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.oncall.id]
}

resource "google_monitoring_alert_policy" "gke_container_restarts" {
  display_name = "GKE container restarts"
  combiner     = "OR"

  conditions {
    display_name = "More than 3 restarts in 15 minutes"

    condition_threshold {
      filter          = "resource.type = \"k8s_container\" AND metric.type = \"kubernetes.io/container/restart_count\" AND resource.label.namespace_name = \"platform\""
      comparison      = "COMPARISON_GT"
      threshold_value = 3
      duration        = "0s"

      aggregations {
        alignment_period   = "900s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.oncall.id]
}

resource "google_monitoring_dashboard" "platform" {
  dashboard_json = file("${path.module}/dashboards/platform.json")
}
