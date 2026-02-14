locals {
  secret_names = toset([
    "anthropic-api-key",
    "openai-api-key",
    "telegram-bot-token",
    "telegram-webhook-secret",
    "manager-webhook-secret",
    "loyalty-api-token",
    "trading-api-token",
    "placement-queue-token",
    "settlement-webhook-secret",
    "vip-bindings",
  ])
}

resource "google_secret_manager_secret" "platform" {
  for_each  = local.secret_names
  secret_id = each.key

  replication {
    auto {}
  }
}
