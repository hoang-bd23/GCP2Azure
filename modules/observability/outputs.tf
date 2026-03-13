output "logging_bucket_id" {
  description = "Cloud Logging bucket ID"
  value       = google_logging_project_bucket_config.central.id
}

output "archive_bucket_name" {
  description = "GCS archive bucket name"
  value       = google_storage_bucket.archive.name
}

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID"
  value       = google_bigquery_dataset.logs.dataset_id
}

output "pubsub_topic_name" {
  description = "Pub/Sub topic name"
  value       = google_pubsub_topic.siem.name
}

output "pubsub_topic_id" {
  description = "Pub/Sub topic ID"
  value       = google_pubsub_topic.siem.id
}

output "functions_sa_email" {
  description = "Cloud Functions service account email"
  value       = google_service_account.cf_sa.email
}

output "functions_source_bucket" {
  description = "GCS bucket for Cloud Functions source code"
  value       = google_storage_bucket.functions_source.name
}
