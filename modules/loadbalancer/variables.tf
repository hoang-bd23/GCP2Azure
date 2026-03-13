variable "project_id" {
  description = "Project ID for load balancer"
  type        = string
}

variable "name" {
  description = "Base name for load balancer resources"
  type        = string
}

variable "backends" {
  description = "Map of backend instance groups"
  type = map(object({
    group           = string
    balancing_mode  = optional(string, "UTILIZATION")
    capacity_scaler = optional(number, 1.0)
    max_utilization = optional(number, 0.8)
  }))
}

variable "health_check_port" {
  description = "Port for health check"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path for HTTP health check"
  type        = string
  default     = "/"
}

variable "enable_cdn" {
  description = "Enable Cloud CDN"
  type        = bool
  default     = false
}

variable "ssl_certificates" {
  description = "List of SSL certificate self links (empty for HTTP-only)"
  type        = list(string)
  default     = []
}
