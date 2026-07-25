variable "project_id" {
  description = "ID of the project in which to create the load balancer."
  type        = string
}

variable "name" {
  description = "Base name used for the load balancer resources."
  type        = string
}

variable "port_range" {
  description = "Port range the plain HTTP global forwarding rule listens on. This front end is never TLS-terminated; use ssl_certificates and https_port_range for HTTPS."
  type        = string
  default     = "80"
}

variable "ip_address" {
  description = "Address or self link of a reserved global external IP to serve from. Null lets Google assign an ephemeral address per forwarding rule, which means the HTTP and HTTPS front ends get different IPs."
  type        = string
  default     = null
}

variable "backend_protocol" {
  description = "Protocol used by the backend service. The health check protocol follows this value."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS", "HTTP2"], var.backend_protocol)
    error_message = "backend_protocol must be one of HTTP, HTTPS or HTTP2."
  }
}

variable "backend_port_name" {
  description = "Named port on the backends the backend service forwards to."
  type        = string
  default     = "http"
}

variable "backend_groups" {
  description = "Self links of instance groups to attach as backends."
  type        = list(string)
  default     = []
}

variable "timeout_sec" {
  description = "Backend service request timeout in seconds."
  type        = number
  default     = 30
}

variable "health_check_port" {
  description = "Fixed port to health check. Null (the default) uses the backends' serving port, which is the port resolved from backend_port_name."
  type        = number
  default     = null
}

variable "health_check_request_path" {
  description = "Path requested by the health check."
  type        = string
  default     = "/"
}

variable "enable_health_check_logging" {
  description = "Emit health check state-change logs to Cloud Logging."
  type        = bool
  default     = true
}

variable "ssl_certificates" {
  description = "Self links of SSL certificates to serve. Supplying at least one creates an HTTPS target proxy and a second global forwarding rule; leaving it empty means the load balancer only ever speaks plain HTTP."
  type        = list(string)
  default     = []
}

variable "https_port_range" {
  description = "Port range the HTTPS global forwarding rule listens on. Only used when ssl_certificates is non-empty."
  type        = string
  default     = "443"
}

variable "enable_http_to_https_redirect" {
  description = "Point the plain HTTP front end at a 301 redirect to HTTPS instead of at the backend service. Only has an effect when ssl_certificates is non-empty."
  type        = bool
  default     = true
}

variable "ssl_policy" {
  description = "Self link of an existing google_compute_ssl_policy to attach to the HTTPS proxy. Null makes the module manage one from ssl_policy_profile and ssl_policy_min_tls_version."
  type        = string
  default     = null
}

variable "ssl_policy_profile" {
  description = "Profile of the module-managed SSL policy. GCP's implicit default when no policy is attached is COMPATIBLE, which still negotiates TLS 1.0 and weak ciphers."
  type        = string
  default     = "MODERN"

  validation {
    condition     = contains(["COMPATIBLE", "MODERN", "RESTRICTED"], var.ssl_policy_profile)
    error_message = "ssl_policy_profile must be one of COMPATIBLE, MODERN or RESTRICTED. CUSTOM is not supported by this module; supply your own policy via ssl_policy instead."
  }
}

variable "ssl_policy_min_tls_version" {
  description = "Minimum TLS version accepted by the module-managed SSL policy."
  type        = string
  default     = "TLS_1_2"

  validation {
    condition     = contains(["TLS_1_0", "TLS_1_1", "TLS_1_2"], var.ssl_policy_min_tls_version)
    error_message = "ssl_policy_min_tls_version must be one of TLS_1_0, TLS_1_1 or TLS_1_2."
  }
}

variable "security_policy" {
  description = "Self link of a Cloud Armor google_compute_security_policy to attach to the backend service. Null leaves the backend service with no WAF or rate limiting in front of it."
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "Enable request logging on the backend service. GCP defaults this off, which leaves no record of served requests."
  type        = bool
  default     = true
}

variable "logging_sample_rate" {
  description = "Fraction of requests logged when enable_logging is true."
  type        = number
  default     = 1.0

  validation {
    condition     = var.logging_sample_rate >= 0 && var.logging_sample_rate <= 1
    error_message = "logging_sample_rate must be between 0.0 and 1.0."
  }
}
