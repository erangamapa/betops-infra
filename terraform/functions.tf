resource "google_cloudfunctions2_function" "news_ingest" {
  name     = "news-ingest"
  location = var.region

  build_config {
    runtime     = "nodejs22"
    entry_point = "handler"

    source {
      storage_source {
        bucket = var.functions_source_bucket
        object = var.news_ingest_source_object
      }
    }
  }

  service_config {
    available_memory      = "256M"
    timeout_seconds       = 30
    max_instance_count    = 20
    ingress_settings      = "ALLOW_INTERNAL_AND_GCLB"
    service_account_email = google_service_account.news_ingest.email

    environment_variables = {
      GCP_PROJECT_ID = var.project_id
      NEWS_TOPIC     = google_pubsub_topic.main["sports-news"].name
    }
  }
}

resource "google_cloudfunctions2_function" "settlement_webhook" {
  name     = "settlement-webhook"
  location = var.region

  build_config {
    runtime     = "nodejs22"
    entry_point = "handler"

    source {
      storage_source {
        bucket = var.functions_source_bucket
        object = var.settlement_webhook_source_object
      }
    }
  }

  service_config {
    available_memory      = "256M"
    timeout_seconds       = 30
    max_instance_count    = 20
    ingress_settings      = "ALLOW_INTERNAL_AND_GCLB"
    service_account_email = google_service_account.settlement_webhook.email

    environment_variables = {
      GCP_PROJECT_ID    = var.project_id
      SETTLEMENTS_TOPIC = google_pubsub_topic.main["bet-settlements"].name
    }

    secret_environment_variables {
      key        = "WEBHOOK_SIGNING_SECRET"
      project_id = var.project_id
      secret     = google_secret_manager_secret.platform["settlement-webhook-secret"].secret_id
      version    = "latest"
    }
  }
}
