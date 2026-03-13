variable "project_id" {
  description = "Project ID for compute instances"
  type        = string
}

variable "name" {
  description = "Name of the VM instance"
  type        = string
}

variable "zone" {
  description = "Zone for the VM"
  type        = string
}

variable "machine_type" {
  description = "Machine type (e.g., e2-medium)"
  type        = string
  default     = "e2-medium"
}

variable "image" {
  description = "Boot disk image"
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "network" {
  description = "VPC network self link"
  type        = string
}

variable "subnetwork" {
  description = "Subnet self link"
  type        = string
}

variable "internal_ip" {
  description = "Static internal IP address"
  type        = string
  default     = null
}

variable "tags" {
  description = "Network tags"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels for the instance"
  type        = map(string)
  default     = {}
}

variable "service_account_email" {
  description = "Service account email for the VM"
  type        = string
  default     = null
}

variable "service_account_scopes" {
  description = "Service account OAuth scopes"
  type        = list(string)
  default     = ["cloud-platform"]
}

variable "install_ops_agent" {
  description = "Whether to install Google Cloud Ops Agent via startup script"
  type        = bool
  default     = true
}

variable "additional_startup_script" {
  description = "Additional startup script to run after Ops Agent installation"
  type        = string
  default     = ""
}

variable "enable_external_ip" {
  description = "Whether to assign an external IP"
  type        = bool
  default     = false
}
