variable "dev_project_id" {
  description = "Dev service project ID"
  type        = string
}

variable "hub_project_id" {
  description = "Hub network project ID (for Shared VPC references)"
  type        = string
}

variable "region" {
  description = "Primary GCP region"
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "Zone for the VM"
  type        = string
  default     = "asia-southeast1-a"
}

variable "network_self_link" {
  description = "Shared VPC network self link"
  type        = string
}

variable "subnet_self_link" {
  description = "Dev subnet self link"
  type        = string
}

variable "vm_machine_type" {
  description = "Machine type for Dev VM"
  type        = string
  default     = "e2-medium"
}
