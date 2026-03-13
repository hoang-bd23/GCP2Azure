variable "project_name" {
  description = "Display name of the GCP project"
  type        = string
}

variable "project_id" {
  description = "Unique project ID"
  type        = string
}

variable "org_id" {
  description = "GCP Organization ID (set this OR folder_id, not both)"
  type        = string
  default     = null
}

variable "folder_id" {
  description = "Folder ID to place the project under (set this OR org_id, not both)"
  type        = string
  default     = null
}

variable "billing_account" {
  description = "Billing account ID"
  type        = string
}

variable "activate_apis" {
  description = "List of APIs to enable on the project"
  type        = list(string)
  default     = ["compute.googleapis.com"]
}

variable "labels" {
  description = "Labels to apply to the project"
  type        = map(string)
  default     = {}
}
