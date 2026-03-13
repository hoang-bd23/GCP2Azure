module "observability" {
  source = "../../modules/observability"

  project_id = var.observability_project_id
  org_id     = var.org_id
  region     = var.region

  # Logging
  logging_bucket_id             = "central-logs"
  logging_bucket_retention_days = 90
  archive_bucket_name           = var.archive_bucket_name
  archive_retention_days        = 365

  # BigQuery
  bigquery_dataset_id = "log_analytics"
  bigquery_location   = "US"

  # Pub/Sub
  pubsub_topic_name = "siem-export"

  # Monitoring
  monitored_projects = [
    var.dev_project_id,
    var.prod_project_id,
  ]

  # Cloud Functions
  functions_bucket_name = var.functions_bucket_name
}
