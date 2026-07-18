variable "project_id" {
  description = "ID of the project in which to create the load balancer."
  type        = string
}

variable "name" {
  description = "Base name used for the load balancer resources."
  type        = string
}

variable "port_range" {
  description = "Port range the global forwarding rule listens on."
  type        = string
  default     = "80"
}

variable "backend_protocol" {
  description = "Protocol used by the backend service."
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
