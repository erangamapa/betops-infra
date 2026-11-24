locals {
  pubsub_topics = toset([
    "sports-news",
    "bet-settlements",
    "feed-events",
    "placement-orders",
  ])
}

resource "google_pubsub_topic" "main" {
  for_each = local.pubsub_topics
  name     = each.key
}

resource "google_pubsub_topic" "dead_letter" {
  for_each = local.pubsub_topics
  name     = "${each.key}-dlq"
}

resource "google_pubsub_subscription" "main" {
  for_each = local.pubsub_topics

  name                       = "${each.key}.pulse-agents"
  topic                      = google_pubsub_topic.main[each.key].id
  ack_deadline_seconds       = 60
  message_retention_duration = "604800s"

  retry_policy {
    minimum_backoff = "5s"
    maximum_backoff = "300s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter[each.key].id
    max_delivery_attempts = var.pubsub_max_delivery_attempts
  }
}

resource "google_pubsub_subscription" "dead_letter" {
  for_each = local.pubsub_topics

  name                       = "${each.key}-dlq-inspect"
  topic                      = google_pubsub_topic.dead_letter[each.key].id
  ack_deadline_seconds       = 60
  message_retention_duration = "1209600s"
}

data "google_project" "current" {}

locals {
  pubsub_service_agent = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_topic_iam_member" "dlq_publisher" {
  for_each = local.pubsub_topics
  topic    = google_pubsub_topic.dead_letter[each.key].name
  role     = "roles/pubsub.publisher"
  member   = local.pubsub_service_agent
}

resource "google_pubsub_subscription_iam_member" "dlq_subscriber" {
  for_each     = local.pubsub_topics
  subscription = google_pubsub_subscription.main[each.key].name
  role         = "roles/pubsub.subscriber"
  member       = local.pubsub_service_agent
}
