output "id" {
  description = "Identifier of the global forwarding rule."
  value       = google_compute_global_forwarding_rule.this.id
}

output "self_link" {
  description = "URI of the global forwarding rule."
  value       = google_compute_global_forwarding_rule.this.self_link
}

output "ip_address" {
  description = "External IP address served by the load balancer."
  value       = google_compute_global_forwarding_rule.this.ip_address
}

output "backend_service_id" {
  description = "Identifier of the backend service."
  value       = google_compute_backend_service.this.id
}
