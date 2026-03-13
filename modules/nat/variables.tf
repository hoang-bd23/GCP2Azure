variable "project_id" {
  description = "Project ID for Cloud NAT"
  type        = string
}

variable "region" {
  description = "Region for Cloud NAT"
  type        = string
}

variable "router_name" {
  description = "Name of the Cloud Router to attach NAT to"
  type        = string
}

variable "nat_name" {
  description = "Name of the Cloud NAT"
  type        = string
}

variable "nat_ip_allocate_option" {
  description = "How external IPs should be allocated (AUTO_ONLY or MANUAL_ONLY)"
  type        = string
  default     = "AUTO_ONLY"
}

variable "source_subnetwork_ip_ranges_to_nat" {
  description = "Which subnet IP ranges to NAT (ALL_SUBNETWORKS_ALL_IP_RANGES or LIST_OF_SUBNETWORKS)"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

variable "subnetworks" {
  description = "List of subnetworks to NAT (when source_subnetwork_ip_ranges_to_nat = LIST_OF_SUBNETWORKS)"
  type = list(object({
    name                    = string
    source_ip_ranges_to_nat = list(string)
  }))
  default = []
}

variable "log_config_enable" {
  description = "Enable NAT logging"
  type        = bool
  default     = true
}

variable "log_config_filter" {
  description = "Logging filter (ERRORS_ONLY, TRANSLATIONS_ONLY, ALL)"
  type        = string
  default     = "ERRORS_ONLY"
}
