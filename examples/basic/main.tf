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

module "load_balancer" {
  source = "../.."

  project_id = var.project_id
  name       = "example-lb"
  port_range = "80"
}

variable "project_id" {
  description = "Project ID to deploy the example load balancer into."
  type        = string
}

variable "region" {
  description = "Region for the google provider."
  type        = string
  default     = "us-central1"
}

output "load_balancer_ip" {
  value = module.load_balancer.ip_address
}
