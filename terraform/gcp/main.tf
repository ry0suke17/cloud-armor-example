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
  cluster  = google_container_cluster.test-cluster.name
  location = var.gcp_region
  name     = "default-pool"
  // you should count up when installing datadog agents, etc.
  initial_node_count = 1
  node_config {
    machine_type = "e2-micro"
    disk_size_gb = 10
  }
  timeouts {
    create = "15m"
  }
}

module "test-app1-policy" {
  source      = "./modules/armor"
  name        = "test-app1-policy"
  description = "security policy for app1"
  rules = [
    {
      action      = "rate_based_ban"
      priority    = 100
      description = "rule for app1 endpoint"
      match = {
        expr = {
          expression = "request.path.matches('/app1')"
        }
      }
      rate_limit_options = {
        exceed_action    = "deny(429)"
        ban_duration_sec = 60
        enforce_on_key   = "IP"
        rate_limit_threshold = {
          count        = 10
          interval_sec = 60
        }
      }
      description = "rule for app1 endpoint"
    },
    {
      action   = "allow"
      priority = 2147483647
      match = {
        versioned_expr = "SRC_IPS_V1"
        config = {
          src_ip_ranges = ["*"]
        }
      }
      description = "default rule"
    }
  ]
}

module "test-app2-policy" {
  source      = "./modules/armor"
  name        = "test-app2-policy"
  description = "security policy for app2"
  rules = [
    {
      action      = "rate_based_ban"
      priority    = 100
      description = "rule for app2 endpoint"
      match = {
        expr = {
          expression = "request.path.matches('/app2')"
        }
      }
      rate_limit_options = {
        exceed_action    = "deny(429)"
        ban_duration_sec = 60
        enforce_on_key   = "IP"
        rate_limit_threshold = {
          count        = 10
          interval_sec = 60
        }
      }
      description = "rule for app2 endpoint"
    },
    {
      action   = "allow"
      priority = 2147483647
      match = {
        versioned_expr = "SRC_IPS_V1"
        config = {
          src_ip_ranges = ["*"]
        }
      }
      description = "default rule"
    }
  ]
}
