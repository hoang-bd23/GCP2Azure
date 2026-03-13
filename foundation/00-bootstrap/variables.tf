variable "org_id" {
  description = "GCP Organization ID (get via: gcloud organizations list)"
  type        = string
}

variable "billing_account" {
  description = "Billing account ID (get via: gcloud billing accounts list)"
  type        = string
}

variable "region" {
  description = "Primary GCP region"
  type        = string
  default     = "asia-southeast1"
}

# ---- Seed Project (created by this layer) ----
variable "seed_project_name" {
  description = "Display name for the bootstrap/seed project"
  type        = string
  default     = "Landing Zone Bootstrap"
}

variable "seed_project_id" {
  description = "Globally unique project ID for the seed project (you choose this)"
  type        = string
}

variable "tf_state_bucket_name" {
  description = "Globally unique name for the Terraform state GCS bucket (you choose this)"
  type        = string
}

variable "tf_sa_name" {
  description = "Service account ID for the Terraform runner"
  type        = string
  default     = "terraform-runner"
}

# ---- Project IDs to be created by later layers (you choose these now) ----
variable "hub_project_id" {
  description = "Project ID for hub network (created in 01-org)"
  type        = string
  default     = "prj-hub-network"
}

variable "observability_project_id" {
  description = "Project ID for central observability (created in 01-org)"
  type        = string
  default     = "prj-central-observability"
}

variable "dev_project_id" {
  description = "Project ID for dev environment (created in 01-org)"
  type        = string
  default     = "prj-dev"
}

variable "prod_project_id" {
  description = "Project ID for prod environment (created in 01-org)"
  type        = string
  default     = "prj-prod"
}
