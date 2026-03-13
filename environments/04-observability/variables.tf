variable "observability_project_id" {
  description = "Central observability project ID"
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

variable "dev_project_id" {
  description = "Dev project ID (for metrics scope)"
  type        = string
}

variable "prod_project_id" {
  description = "Prod project ID (for metrics scope)"
  type        = string
}

variable "archive_bucket_name" {
  description = "GCS bucket name for log archive"
  type        = string
}

variable "functions_bucket_name" {
  description = "GCS bucket name for Cloud Functions source"
  type        = string
}
