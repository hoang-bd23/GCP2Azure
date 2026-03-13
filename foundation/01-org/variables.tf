variable "project_id" {
  description = "Bootstrap project ID (for provider default)"
  type        = string
}

variable "region" {
  description = "Primary GCP region"
  type        = string
  default     = "asia-southeast1"
}

variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "billing_account" {
  description = "Billing account ID"
  type        = string
}

variable "hub_project_id" {
  description = "Project ID for the hub network project"
  type        = string
  default     = "prj-hub-network"
}

variable "observability_project_id" {
  description = "Project ID for the central observability project"
  type        = string
  default     = "prj-central-observability"
}

variable "dev_project_id" {
  description = "Project ID for the dev service project"
  type        = string
  default     = "prj-dev"
}

variable "prod_project_id" {
  description = "Project ID for the prod service project"
  type        = string
  default     = "prj-prod"
}
