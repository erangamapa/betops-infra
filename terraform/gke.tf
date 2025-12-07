resource "google_container_cluster" "platform" {
  name     = "platform"
  location = var.region

  network    = google_compute_network.platform.id
  subnetwork = google_compute_subnetwork.gke.id

  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = true

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  resource_labels = {
    environment = var.environment
  }
}

resource "google_container_node_pool" "general" {
  name     = "general"
  cluster  = google_container_cluster.platform.id
  location = var.region

  autoscaling {
    min_node_count = 1
    max_node_count = var.gke_general_max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = var.gke_general_machine_type
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}

resource "google_container_node_pool" "gpu" {
  name     = "gpu"
  cluster  = google_container_cluster.platform.id
  location = var.region

  node_locations = ["${var.region}-b"]

  autoscaling {
    min_node_count = 0
    max_node_count = 2
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = var.gke_gpu_machine_type
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    guest_accelerator {
      type  = "nvidia-l4"
      count = 1

      gpu_driver_installation_config {
        gpu_driver_version = "DEFAULT"
      }
    }

    taint {
      key    = "nvidia.com/gpu"
      value  = "present"
      effect = "NO_SCHEDULE"
    }

    labels = {
      workload = "vllm"
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}
