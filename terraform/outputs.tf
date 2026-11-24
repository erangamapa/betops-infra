output "gke_cluster_name" {
  description = "Name of the GKE cluster."
  value       = google_container_cluster.platform.name
}

output "artifact_registry_url" {
  description = "Docker repository path for pushing images."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.platform.repository_id}"
}

output "pubsub_topics" {
  description = "Main topic names."
  value       = [for topic in google_pubsub_topic.main : topic.name]
}

output "placement_queue" {
  description = "Cloud Tasks queue that shapes placement dispatch."
  value       = google_cloud_tasks_queue.placement_dispatch.id
}

output "player_replies_url" {
  description = "Cloud Run URL for player-replies."
  value       = google_cloud_run_v2_service.player_replies.uri
}

output "k8s_service_account_emails" {
  description = "Google service accounts bound to the platform namespace."
  value = {
    pulse-agents  = google_service_account.pulse_agents.email
    vip-concierge = google_service_account.vip_concierge.email
    vllm          = google_service_account.vllm.email
    scoring       = google_service_account.scoring.email
  }
}
