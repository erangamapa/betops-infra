resource "google_artifact_registry_repository" "platform" {
  repository_id = "platform"
  location      = var.region
  format        = "DOCKER"
  description   = "Container images for the platform services."

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"

    most_recent_versions {
      keep_count = 20
    }
  }

  cleanup_policies {
    id     = "drop-old"
    action = "DELETE"

    condition {
      older_than = "2592000s"
    }
  }
}
