output "id" {
  description = "Identifier of the HTTP global forwarding rule."
  value       = google_compute_global_forwarding_rule.this.id
}

output "self_link" {
  description = "URI of the HTTP global forwarding rule."
  value       = google_compute_global_forwarding_rule.this.self_link
}

output "ip_address" {
  description = "External IP address served by the HTTP forwarding rule."
  value       = google_compute_global_forwarding_rule.this.ip_address
}

output "https_id" {
  description = "Identifier of the HTTPS global forwarding rule, or null when no SSL certificates were supplied."
  value       = one(google_compute_global_forwarding_rule.https[*].id)
}

output "https_ip_address" {
  description = "External IP address served by the HTTPS forwarding rule, or null when no SSL certificates were supplied."
  value       = one(google_compute_global_forwarding_rule.https[*].ip_address)
}

output "backend_service_id" {
  description = "Identifier of the backend service."
  value       = google_compute_backend_service.this.id
}

output "health_check_id" {
  description = "Identifier of the health check."
  value       = google_compute_health_check.this.id
}

output "ssl_policy_id" {
  description = "Identifier of the SSL policy attached to the HTTPS proxy: the module-managed policy, the caller-supplied one, or null when the load balancer serves no HTTPS."
  value       = local.https_enabled ? local.ssl_policy_id : null
}
