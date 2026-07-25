terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# A single reserved address so the HTTP and HTTPS front ends answer on the same
# IP and one DNS A record covers both.
resource "google_compute_global_address" "this" {
  project = var.project_id
  name    = "example-https-lb-ip"
}

resource "google_compute_managed_ssl_certificate" "this" {
  project = var.project_id
  name    = "example-https-lb-cert"

  managed {
    domains = [var.domain]
  }
}

# Cloud Armor in front of the backend service. The preconfigured WAF rules are
# only worth paying for once they are actually attached, which the module does
# via security_policy below.
resource "google_compute_security_policy" "this" {
  project = var.project_id
  name    = "example-https-lb-armor"

  rule {
    action   = "deny(403)"
    priority = 1000
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
    description = "Block cross-site scripting attempts."
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
    description = "Default rule, higher priority overrides it."
  }
}

module "load_balancer" {
  source = "../.."

  project_id = var.project_id
  name       = "example-https-lb"

  ip_address       = google_compute_global_address.this.address
  ssl_certificates = [google_compute_managed_ssl_certificate.this.id]
  security_policy  = google_compute_security_policy.this.id

  # Defaults worth knowing about, spelled out here:
  #   enable_http_to_https_redirect = true      HTTP 301s to HTTPS
  #   ssl_policy_profile            = "MODERN"  no TLS 1.0/1.1
  #   enable_logging                = true      request logs to Cloud Logging
}

variable "project_id" {
  description = "Project ID to deploy the example load balancer into."
  type        = string
}

variable "domain" {
  description = "Domain the managed certificate is issued for. Its DNS A record must point at the reserved address before the certificate can provision."
  type        = string
}

variable "region" {
  description = "Region for the google provider."
  type        = string
  default     = "us-central1"
}

output "load_balancer_ip" {
  description = "Address serving both the HTTP redirect and the HTTPS front end."
  value       = google_compute_global_address.this.address
}

output "ssl_policy_id" {
  description = "SSL policy the module created and attached to the HTTPS proxy."
  value       = module.load_balancer.ssl_policy_id
}
