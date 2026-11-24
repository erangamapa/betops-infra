resource "google_cloud_tasks_queue" "placement_dispatch" {
  name     = "placement-dispatch"
  location = var.region

  rate_limits {
    max_dispatches_per_second = 50
    max_concurrent_dispatches = 20
  }

  retry_config {
    max_attempts       = 8
    min_backoff        = "2s"
    max_backoff        = "120s"
    max_doublings      = 4
    max_retry_duration = "900s"
  }

  stackdriver_logging_config {
    sampling_ratio = 0.2
  }
}
