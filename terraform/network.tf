resource "google_compute_network" "platform" {
  name                    = "platform"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke" {
  name                     = "gke-${var.region}"
  region                   = var.region
  network                  = google_compute_network.platform.id
  ip_cidr_range            = "10.10.0.0/20"
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

resource "google_compute_subnetwork" "serverless" {
  name                     = "serverless-${var.region}"
  region                   = var.region
  network                  = google_compute_network.platform.id
  ip_cidr_range            = "10.11.0.0/24"
  private_ip_google_access = true
}

resource "google_compute_global_address" "private_service_range" {
  name          = "private-service-access"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.platform.id
}

resource "google_service_networking_connection" "private_service_access" {
  network                 = google_compute_network.platform.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]
}

resource "google_compute_router" "egress" {
  name    = "egress-${var.region}"
  region  = var.region
  network = google_compute_network.platform.id
}

resource "google_compute_router_nat" "egress" {
  name                               = "egress-${var.region}"
  region                             = var.region
  router                             = google_compute_router.egress.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
