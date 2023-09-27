# terraform version v1.5.7

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
  default = "us-west1"
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_container_cluster" "test-cluster" {
  project = var.gcp_project
  name               = "test-cluster"
  location           = var.gcp_region
  initial_node_count = 2
  min_master_version = "1.27.3-gke.100"
  node_config {
    # See below for GCE pricing.
    # ref. https://cloud.google.com/compute/all-pricing
    machine_type = "e2-micro"
    disk_size_gb = 10
  }
}

resource "google_compute_security_policy" "test-app1-policy" {
  name = "test-policy-app1"
  rule {
    action   = "rate_based_ban"
    priority = 100
    match {
      expr {
        expression = "request.path.matches('/app1')"
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      ban_duration_sec = 60
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 10
        interval_sec = 60
      }
    }
  }
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default rule"
  }
}

resource "google_compute_security_policy" "test-app2-policy" {
  name = "test-policy-app2"
  rule {
    action   = "rate_based_ban"
    priority = 100
    match {
      expr {
        expression = "request.path.matches('/app2')"
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      ban_duration_sec = 60
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 10
        interval_sec = 60
      }
    }
  }
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default rule"
  }
}