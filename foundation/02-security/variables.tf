variable "project_id" {
  description = "Observability project ID (hosts KMS and SCC config)"
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

variable "terraform_sa_email" {
  description = "Terraform service account email for IAM bindings"
  type        = string
}

variable "kms_key_ring_name" {
  description = "Name for the KMS key ring"
  type        = string
  default     = "landing-zone-keyring"
}

variable "kms_keys" {
  description = "List of KMS key names"
  type        = list(string)
  default     = ["default-key", "logging-key"]
}
