variable "project_id" {
  description = "Project ID for observability resources"
  type        = string
}

variable "org_id" {
  description = "Organization ID for aggregated log sinks"
  type        = string
}

variable "region" {
  description = "Region for storage resources"
  type        = string
}

# Logging
variable "logging_bucket_id" {
  description = "ID for the Cloud Logging bucket"
  type        = string
  default     = "central-logs"
}

variable "logging_bucket_retention_days" {
  description = "Retention period for Cloud Logging bucket (days)"
  type        = number
  default     = 90
}

variable "archive_bucket_name" {
  description = "Name for GCS archive bucket"
  type        = string
}

variable "archive_retention_days" {
  description = "Retention period for GCS archive (days)"
  type        = number
  default     = 365
}

# BigQuery
variable "bigquery_dataset_id" {
  description = "BigQuery dataset ID for log analytics"
  type        = string
  default     = "log_analytics"
}

variable "bigquery_location" {
  description = "BigQuery dataset location"
  type        = string
  default     = "US"
}

# Pub/Sub
variable "pubsub_topic_name" {
  description = "Pub/Sub topic name for SIEM export"
  type        = string
  default     = "siem-export"
}

# Monitoring
variable "monitored_projects" {
  description = "List of project IDs to add to the metrics scope"
  type        = list(string)
  default     = []
}

# Cloud Functions
variable "functions_bucket_name" {
  description = "GCS bucket name for Cloud Functions source code"
  type        = string
}

variable "functions_source_dir" {
  description = "Local directory path containing Cloud Functions source code"
  type        = string
  default     = ""
}
