# terraform version v1.5.7

# need to run `export TF_VAR_gcp_project=your-gcp-project` in advance
variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type    = string
  default = "us-east1"
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
  project                  = var.gcp_project
  name                     = "test-cluster"
  location                 = var.gcp_region
  min_master_version       = "1.27.3-gke.100"
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "test-cluster-node-pool" {
  cluster            = google_container_cluster.test-cluster.name
  location           = var.gcp_region
  name               = "default-pool"
  initial_node_count = 2
  node_config {
    machine_type = "e2-micro"
    disk_size_gb = 10
  }
  timeouts {
    create = "15m"
  }
}

resource "google_compute_security_policy" "test-app1-policy" {
  name = "test-app1-policy"
  rule {
    action   = "rate_based_ban"
    priority = 100
    preview = false
    match {
      expr {
        expression = "request.path.matches('/app1')"
      }
    }
    rate_limit_options {
      conform_action   = "allow"
      exceed_action    = "deny(429)"
      ban_duration_sec = 60
      enforce_on_key   = "IP"
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
  name = "test-app2-policy"
  rule {
    action   = "rate_based_ban"
    priority = 100
    preview = false
    match {
      expr {
        expression = "request.path.matches('/app2')"
      }
    }
    rate_limit_options {
      conform_action   = "allow"
      exceed_action    = "deny(429)"
      ban_duration_sec = 60
      enforce_on_key   = "IP"
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
