# Test-only requirement: `mock_provider` needs Terraform >= 1.7 / OpenTofu >= 1.7.
# The module itself still supports >= 1.5, so versions.tf is deliberately not bumped.

mock_provider "google" {}

variables {
  project_id = "test-project"
  name       = "test-lb"
}

run "http_only_by_default" {
  assert {
    condition     = length(google_compute_ssl_policy.this) == 0
    error_message = "No SSL policy should be managed when no certificates are supplied."
  }

  assert {
    condition     = length(google_compute_target_https_proxy.this) == 0
    error_message = "No HTTPS proxy should exist when no certificates are supplied."
  }

  assert {
    condition     = length(google_compute_url_map.redirect) == 0
    error_message = "The HTTP front end must keep serving the backend service when there is no HTTPS front end to redirect to."
  }

  assert {
    condition     = google_compute_target_http_proxy.this.url_map == google_compute_url_map.this.id
    error_message = "The HTTP proxy must point at the service URL map when redirects are not in play."
  }
}

run "backend_service_logs_by_default" {
  assert {
    condition     = google_compute_backend_service.this.log_config[0].enable
    error_message = "Backend service request logging must be on by default; GCP defaults it off."
  }

  assert {
    condition     = google_compute_backend_service.this.log_config[0].sample_rate == 1
    error_message = "Default logging sample rate should capture every request."
  }
}

run "health_check_follows_serving_port" {
  variables {
    backend_port_name = "http-8080"
  }

  assert {
    condition     = google_compute_health_check.this.http_health_check[0].port_specification == "USE_SERVING_PORT"
    error_message = "A hard-coded health check port ignores backend_port_name and fails every backend that does not serve on it."
  }

  assert {
    condition     = google_compute_health_check.this.log_config[0].enable
    error_message = "Health check logging should be on by default."
  }
}

run "health_check_protocol_follows_backend_protocol" {
  variables {
    backend_protocol = "HTTPS"
  }

  assert {
    condition     = length(google_compute_health_check.this.https_health_check) == 1
    error_message = "An HTTPS backend service must be checked over HTTPS, otherwise no backend ever becomes healthy."
  }

  assert {
    condition     = length(google_compute_health_check.this.http_health_check) == 0
    error_message = "A plain HTTP health check must not be emitted for an HTTPS backend service."
  }
}

run "health_check_protocol_http2" {
  variables {
    backend_protocol = "HTTP2"
  }

  assert {
    condition     = length(google_compute_health_check.this.http2_health_check) == 1
    error_message = "An HTTP/2 backend service must be checked over HTTP/2."
  }
}

run "explicit_health_check_port_is_honoured" {
  variables {
    health_check_port = 8443
  }

  assert {
    condition     = google_compute_health_check.this.http_health_check[0].port_specification == "USE_FIXED_PORT"
    error_message = "Setting health_check_port must pin the check to that port."
  }

  assert {
    condition     = google_compute_health_check.this.http_health_check[0].port == 8443
    error_message = "Setting health_check_port must pin the check to that port."
  }
}

run "https_front_end_hardens_tls" {
  variables {
    ssl_certificates = ["projects/test-project/global/sslCertificates/test-cert"]
  }

  assert {
    condition     = google_compute_ssl_policy.this[0].min_tls_version == "TLS_1_2"
    error_message = "Leaving the SSL policy unset falls back to GCP's COMPATIBLE profile, which still permits TLS 1.0."
  }

  assert {
    condition     = google_compute_ssl_policy.this[0].profile == "MODERN"
    error_message = "The module-managed SSL policy should default to the MODERN profile."
  }

  assert {
    condition     = google_compute_target_https_proxy.this[0].ssl_policy == google_compute_ssl_policy.this[0].id
    error_message = "An SSL policy that is created but not attached to the proxy buys nothing."
  }

  assert {
    condition     = google_compute_global_forwarding_rule.https[0].port_range == "443"
    error_message = "The HTTPS forwarding rule should listen on 443 by default."
  }
}

run "http_redirects_to_https_by_default" {
  variables {
    ssl_certificates = ["projects/test-project/global/sslCertificates/test-cert"]
  }

  assert {
    condition     = google_compute_url_map.redirect[0].default_url_redirect[0].https_redirect
    error_message = "With an HTTPS front end available, plain HTTP should be redirected rather than served."
  }

  assert {
    condition     = google_compute_target_http_proxy.this.url_map == google_compute_url_map.redirect[0].id
    error_message = "The HTTP proxy must point at the redirect URL map when redirects are enabled."
  }
}

run "http_redirect_can_be_disabled" {
  variables {
    ssl_certificates              = ["projects/test-project/global/sslCertificates/test-cert"]
    enable_http_to_https_redirect = false
  }

  assert {
    condition     = length(google_compute_url_map.redirect) == 0
    error_message = "Disabling the redirect must leave the HTTP front end serving the backend service."
  }

  assert {
    condition     = google_compute_target_http_proxy.this.url_map == google_compute_url_map.this.id
    error_message = "Disabling the redirect must leave the HTTP front end serving the backend service."
  }
}

run "caller_supplied_ssl_policy_wins" {
  variables {
    ssl_certificates = ["projects/test-project/global/sslCertificates/test-cert"]
    ssl_policy       = "projects/test-project/global/sslPolicies/corp-policy"
  }

  assert {
    condition     = length(google_compute_ssl_policy.this) == 0
    error_message = "The module must not manage an SSL policy when the caller supplies one."
  }

  assert {
    condition     = google_compute_target_https_proxy.this[0].ssl_policy == "projects/test-project/global/sslPolicies/corp-policy"
    error_message = "The caller-supplied SSL policy must be attached to the HTTPS proxy."
  }
}

run "security_policy_is_attached" {
  variables {
    security_policy = "projects/test-project/global/securityPolicies/armor"
  }

  assert {
    condition     = google_compute_backend_service.this.security_policy == "projects/test-project/global/securityPolicies/armor"
    error_message = "Cloud Armor policy must reach the backend service."
  }
}

run "shared_ip_reaches_both_forwarding_rules" {
  variables {
    ip_address       = "203.0.113.10"
    ssl_certificates = ["projects/test-project/global/sslCertificates/test-cert"]
  }

  assert {
    condition     = google_compute_global_forwarding_rule.this.ip_address == "203.0.113.10"
    error_message = "The reserved address must be used by the HTTP forwarding rule."
  }

  assert {
    condition     = google_compute_global_forwarding_rule.https[0].ip_address == "203.0.113.10"
    error_message = "The reserved address must be used by the HTTPS forwarding rule, otherwise the redirect target resolves elsewhere."
  }
}

run "rejects_invalid_backend_protocol" {
  command = plan

  variables {
    backend_protocol = "TCP"
  }

  expect_failures = [var.backend_protocol]
}

run "rejects_invalid_ssl_policy_profile" {
  command = plan

  variables {
    ssl_policy_profile = "CUSTOM"
  }

  expect_failures = [var.ssl_policy_profile]
}

run "rejects_invalid_min_tls_version" {
  command = plan

  variables {
    ssl_policy_min_tls_version = "TLS_1_3"
  }

  expect_failures = [var.ssl_policy_min_tls_version]
}

run "rejects_out_of_range_sample_rate" {
  command = plan

  variables {
    logging_sample_rate = 1.5
  }

  expect_failures = [var.logging_sample_rate]
}
