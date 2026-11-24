resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes"
  display_name = "GKE node pools"
}

resource "google_service_account" "pulse_agents" {
  account_id   = "pulse-agents"
  display_name = "pulse-agents workload"
}

resource "google_service_account" "vip_concierge" {
  account_id   = "vip-concierge"
  display_name = "pulse-vip-concierge workload"
}

resource "google_service_account" "vllm" {
  account_id   = "vllm-serving"
  display_name = "vllm serving workload"
}

resource "google_service_account" "scoring" {
  account_id   = "scoring"
  display_name = "scoring sidecar workload"
}

resource "google_service_account" "player_replies" {
  account_id   = "player-replies"
  display_name = "player-replies Cloud Run service"
}

resource "google_service_account" "news_ingest" {
  account_id   = "news-ingest"
  display_name = "news-ingest function"
}

resource "google_service_account" "settlement_webhook" {
  account_id   = "settlement-webhook"
  display_name = "settlement-webhook function"
}

resource "google_project_iam_member" "gke_nodes" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_pubsub_subscription_iam_member" "pulse_agents_subscribe" {
  for_each     = local.pubsub_topics
  subscription = google_pubsub_subscription.main[each.key].name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.pulse_agents.email}"
}

resource "google_pubsub_topic_iam_member" "pulse_agents_publish" {
  for_each = toset(["placement-orders", "feed-events"])
  topic    = google_pubsub_topic.main[each.key].name
  role     = "roles/pubsub.publisher"
  member   = "serviceAccount:${google_service_account.pulse_agents.email}"
}

resource "google_cloud_tasks_queue_iam_member" "pulse_agents_enqueue" {
  name     = google_cloud_tasks_queue.placement_dispatch.name
  location = var.region
  role     = "roles/cloudtasks.enqueuer"
  member   = "serviceAccount:${google_service_account.pulse_agents.email}"
}

resource "google_cloud_tasks_queue_iam_member" "vip_concierge_enqueue" {
  name     = google_cloud_tasks_queue.placement_dispatch.name
  location = var.region
  role     = "roles/cloudtasks.enqueuer"
  member   = "serviceAccount:${google_service_account.vip_concierge.email}"
}

resource "google_pubsub_topic_iam_member" "news_ingest_publish" {
  topic  = google_pubsub_topic.main["sports-news"].name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.news_ingest.email}"
}

resource "google_pubsub_topic_iam_member" "settlement_webhook_publish" {
  topic  = google_pubsub_topic.main["bet-settlements"].name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.settlement_webhook.email}"
}

locals {
  secret_access = {
    pulse_agents = {
      account = google_service_account.pulse_agents.email
      secrets = ["anthropic-api-key", "openai-api-key"]
    }
    vip_concierge = {
      account = google_service_account.vip_concierge.email
      secrets = [
        "anthropic-api-key",
        "openai-api-key",
        "telegram-bot-token",
        "telegram-webhook-secret",
        "manager-webhook-secret",
        "loyalty-api-token",
        "trading-api-token",
        "placement-queue-token",
        "vip-bindings",
      ]
    }
    player_replies = {
      account = google_service_account.player_replies.email
      secrets = ["anthropic-api-key"]
    }
    settlement_webhook = {
      account = google_service_account.settlement_webhook.email
      secrets = ["settlement-webhook-secret"]
    }
  }

  secret_bindings = merge([
    for workload, grant in local.secret_access : {
      for secret in grant.secrets : "${workload}/${secret}" => {
        account = grant.account
        secret  = secret
      }
    }
  ]...)
}

resource "google_secret_manager_secret_iam_member" "access" {
  for_each  = local.secret_bindings
  secret_id = google_secret_manager_secret.platform[each.value.secret].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value.account}"
}

locals {
  k8s_workload_identities = {
    pulse-agents  = google_service_account.pulse_agents.name
    vip-concierge = google_service_account.vip_concierge.name
    vllm          = google_service_account.vllm.name
    scoring       = google_service_account.scoring.name
  }
}

resource "google_service_account_iam_member" "workload_identity" {
  for_each           = local.k8s_workload_identities
  service_account_id = each.value
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[platform/${each.key}]"
}
