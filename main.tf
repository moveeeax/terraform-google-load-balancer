locals {
  # An HTTPS front end is created as soon as the caller supplies certificates.
  https_enabled = length(var.ssl_certificates) > 0

  # Only manage an SSL policy when we serve HTTPS and the caller has not
  # brought their own. GCP's implicit default policy is the COMPATIBLE profile
  # with a TLS 1.0 floor, so leaving this unset is never the right answer.
  create_ssl_policy = local.https_enabled && var.ssl_policy == null
  ssl_policy_id     = local.create_ssl_policy ? google_compute_ssl_policy.this[0].id : var.ssl_policy

  # Plain HTTP is only ever redirected once there is somewhere to redirect to.
  http_redirect = local.https_enabled && var.enable_http_to_https_redirect

  # A fixed health check port silently ignores the backend service's named
  # port. Following the serving port keeps the check aimed at whatever the
  # instance group actually listens on.
  health_check_port_specification = var.health_check_port == null ? "USE_SERVING_PORT" : "USE_FIXED_PORT"
}

resource "google_compute_health_check" "this" {
  project = var.project_id
  name    = "${var.name}-hc"

  # The health check protocol has to match what the backends speak, otherwise
  # an HTTPS or HTTP/2 backend service never passes its checks.
  dynamic "http_health_check" {
    for_each = var.backend_protocol == "HTTP" ? [1] : []
    content {
      port_specification = local.health_check_port_specification
      port               = var.health_check_port
      request_path       = var.health_check_request_path
    }
  }

  dynamic "https_health_check" {
    for_each = var.backend_protocol == "HTTPS" ? [1] : []
    content {
      port_specification = local.health_check_port_specification
      port               = var.health_check_port
      request_path       = var.health_check_request_path
    }
  }

  dynamic "http2_health_check" {
    for_each = var.backend_protocol == "HTTP2" ? [1] : []
    content {
      port_specification = local.health_check_port_specification
      port               = var.health_check_port
      request_path       = var.health_check_request_path
    }
  }

  log_config {
    enable = var.enable_health_check_logging
  }
}

resource "google_compute_backend_service" "this" {
  project               = var.project_id
  name                  = "${var.name}-backend"
  protocol              = var.backend_protocol
  port_name             = var.backend_port_name
  timeout_sec           = var.timeout_sec
  health_checks         = [google_compute_health_check.this.id]
  load_balancing_scheme = "EXTERNAL"

  # Cloud Armor. Null leaves the backend service unprotected, which is the
  # GCP default, so callers facing the internet should set this.
  security_policy = var.security_policy

  # Request logging is off by default in GCP; without it there is no record of
  # what the load balancer served.
  log_config {
    enable      = var.enable_logging
    sample_rate = var.enable_logging ? var.logging_sample_rate : 0
  }

  dynamic "backend" {
    for_each = var.backend_groups
    content {
      group = backend.value
    }
  }
}

resource "google_compute_url_map" "this" {
  project         = var.project_id
  name            = "${var.name}-urlmap"
  default_service = google_compute_backend_service.this.id
}

# Serves 301s to https:// on the plain HTTP front end.
resource "google_compute_url_map" "redirect" {
  count = local.http_redirect ? 1 : 0

  project = var.project_id
  name    = "${var.name}-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_ssl_policy" "this" {
  count = local.create_ssl_policy ? 1 : 0

  project         = var.project_id
  name            = "${var.name}-ssl-policy"
  profile         = var.ssl_policy_profile
  min_tls_version = var.ssl_policy_min_tls_version
}

resource "google_compute_target_http_proxy" "this" {
  project = var.project_id
  name    = "${var.name}-proxy"
  url_map = local.http_redirect ? google_compute_url_map.redirect[0].id : google_compute_url_map.this.id
}

resource "google_compute_target_https_proxy" "this" {
  count = local.https_enabled ? 1 : 0

  project          = var.project_id
  name             = "${var.name}-https-proxy"
  url_map          = google_compute_url_map.this.id
  ssl_certificates = var.ssl_certificates
  ssl_policy       = local.ssl_policy_id
}

resource "google_compute_global_forwarding_rule" "this" {
  project               = var.project_id
  name                  = var.name
  target                = google_compute_target_http_proxy.this.id
  port_range            = var.port_range
  ip_address            = var.ip_address
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "https" {
  count = local.https_enabled ? 1 : 0

  project               = var.project_id
  name                  = "${var.name}-https"
  target                = google_compute_target_https_proxy.this[0].id
  port_range            = var.https_port_range
  ip_address            = var.ip_address
  load_balancing_scheme = "EXTERNAL"
}
