variable "project_id" {
  description = "GCP project that hosts the whole platform."
  type        = string
}

variable "region" {
  description = "Primary region for every regional resource."
  type        = string
  default     = "europe-west2"
}

variable "environment" {
  description = "Short environment name used in resource labels."
  type        = string
  default     = "prod"
}

variable "gke_general_machine_type" {
  description = "Machine type for the general node pool."
  type        = string
  default     = "e2-standard-4"
}

variable "gke_general_max_nodes" {
  description = "Per zone autoscaling ceiling for the general pool."
  type        = number
  default     = 4
}

variable "gke_gpu_machine_type" {
  description = "Machine type for the GPU pool. g2 shapes carry nvidia-l4."
  type        = string
  default     = "g2-standard-8"
}

variable "functions_source_bucket" {
  description = "Bucket that holds the zipped function sources."
  type        = string
}

variable "news_ingest_source_object" {
  description = "Object name of the news-ingest source archive."
  type        = string
  default     = "news-ingest.zip"
}

variable "settlement_webhook_source_object" {
  description = "Object name of the settlement-webhook source archive."
  type        = string
  default     = "settlement-webhook.zip"
}

variable "player_replies_image" {
  description = "Container image for the player-replies Cloud Run service."
  type        = string
  default     = "europe-west2-docker.pkg.dev/oddsmith-platform/platform/player-replies:latest"
}

variable "alert_email" {
  description = "Address that receives alert policy notifications."
  type        = string
  default     = "oncall@sportsbook.internal"
}

variable "pubsub_max_delivery_attempts" {
  description = "Deliveries before a message moves to its dead letter topic."
  type        = number
  default     = 5
}
