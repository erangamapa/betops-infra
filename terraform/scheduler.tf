resource "google_cloud_scheduler_job" "persona_posting_slots" {
  name      = "persona-posting-slots"
  region    = var.region
  schedule  = "*/5 * * * *"
  time_zone = "Etc/UTC"

  pubsub_target {
    topic_name = google_pubsub_topic.main["feed-events"].id
    data       = base64encode(jsonencode({ type = "persona.posting-slot" }))
  }

  retry_config {
    retry_count = 1
  }
}

resource "google_cloud_scheduler_job" "daily_judge_sample" {
  name      = "daily-judge-sample"
  region    = var.region
  schedule  = "0 3 * * *"
  time_zone = "Etc/UTC"

  pubsub_target {
    topic_name = google_pubsub_topic.main["feed-events"].id
    data       = base64encode(jsonencode({ type = "eval.daily-judge-sample" }))
  }

  retry_config {
    retry_count = 2
  }
}
