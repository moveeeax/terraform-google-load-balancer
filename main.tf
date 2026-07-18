resource "google_compute_health_check" "this" {
  project = var.project_id
  name    = "${var.name}-hc"

  http_health_check {
    port = 80
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

resource "google_compute_target_http_proxy" "this" {
  project = var.project_id
  name    = "${var.name}-proxy"
  url_map = google_compute_url_map.this.id
}

resource "google_compute_global_forwarding_rule" "this" {
  project               = var.project_id
  name                  = var.name
  target                = google_compute_target_http_proxy.this.id
  port_range            = var.port_range
  load_balancing_scheme = "EXTERNAL"
}
