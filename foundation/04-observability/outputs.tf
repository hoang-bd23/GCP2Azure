output "logging_bucket_id" {
  description = "Cloud Logging bucket ID"
  value       = module.observability.logging_bucket_id
}

output "archive_bucket_name" {
  description = "GCS archive bucket name"
  value       = module.observability.archive_bucket_name
}

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID for log analytics"
  value       = module.observability.bigquery_dataset_id
}

output "pubsub_topic_name" {
  description = "Pub/Sub topic for SIEM export"
  value       = module.observability.pubsub_topic_name
}

output "functions_sa_email" {
  description = "Cloud Functions service account email"
  value       = module.observability.functions_sa_email
}
