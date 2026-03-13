###############################################################################
# Aggregated Log Sink (Org-level → this project)
###############################################################################
resource "google_logging_organization_sink" "aggregated" {
  name             = "aggregated-sink-to-${var.project_id}"
  org_id           = var.org_id
  destination      = "logging.googleapis.com/projects/${var.project_id}/locations/global/buckets/${var.logging_bucket_id}"
  include_children = true
  filter           = ""
}

resource "google_project_iam_member" "log_sink_writer" {
  project = var.project_id
  role    = "roles/logging.bucketWriter"
  member  = google_logging_organization_sink.aggregated.writer_identity
}

###############################################################################
# Cloud Logging Bucket (Hot Storage)
###############################################################################
resource "google_logging_project_bucket_config" "central" {
  project        = var.project_id
  location       = "global"
  bucket_id      = var.logging_bucket_id
  retention_days = var.logging_bucket_retention_days
}

###############################################################################
# GCS Archive Bucket (Cold Storage)
###############################################################################
resource "google_storage_bucket" "archive" {
  name          = var.archive_bucket_name
  project       = var.project_id
  location      = var.region
  storage_class = "ARCHIVE"
  force_destroy = false

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = var.archive_retention_days
    }
    action {
      type = "Delete"
    }
  }
}

# Sink to GCS archive
resource "google_logging_organization_sink" "gcs_archive" {
  name             = "archive-sink-to-gcs"
  org_id           = var.org_id
  destination      = "storage.googleapis.com/${google_storage_bucket.archive.name}"
  include_children = true
  filter           = ""
}

resource "google_storage_bucket_iam_member" "archive_sink_writer" {
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.objectCreator"
  member = google_logging_organization_sink.gcs_archive.writer_identity
}

###############################################################################
# BigQuery (Log Analytics)
###############################################################################
resource "google_bigquery_dataset" "logs" {
  dataset_id = var.bigquery_dataset_id
  project    = var.project_id
  location   = var.bigquery_location

  default_table_expiration_ms = null

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }
}

# Sink to BigQuery
resource "google_logging_organization_sink" "bigquery" {
  name             = "analytics-sink-to-bigquery"
  org_id           = var.org_id
  destination      = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.logs.dataset_id}"
  include_children = true
  filter           = ""

  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_project_iam_member" "bq_sink_writer" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = google_logging_organization_sink.bigquery.writer_identity
}

###############################################################################
# Pub/Sub (SIEM Export)
###############################################################################
resource "google_pubsub_topic" "siem" {
  name    = var.pubsub_topic_name
  project = var.project_id
}

# Sink to Pub/Sub
resource "google_logging_organization_sink" "pubsub" {
  name             = "siem-sink-to-pubsub"
  org_id           = var.org_id
  destination      = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.siem.name}"
  include_children = true
  filter           = "severity >= WARNING"
}

resource "google_pubsub_topic_iam_member" "pubsub_sink_writer" {
  project = var.project_id
  topic   = google_pubsub_topic.siem.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_organization_sink.pubsub.writer_identity
}

###############################################################################
# Cloud Functions (Security Auto-Remediation)
###############################################################################
resource "google_storage_bucket" "functions_source" {
  name          = var.functions_bucket_name
  project       = var.project_id
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_service_account" "cf_sa" {
  account_id   = "security-auto-remediation"
  display_name = "Security Auto-Remediation Cloud Function SA"
  project      = var.project_id
}

resource "google_project_iam_member" "cf_sa_roles" {
  for_each = toset([
    "roles/compute.securityAdmin",
    "roles/iam.securityReviewer",
    "roles/logging.logWriter",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cf_sa.email}"
}

###############################################################################
# Monitoring — Metrics Scope
###############################################################################
resource "google_monitoring_monitored_project" "scoped" {
  for_each = toset(var.monitored_projects)

  metrics_scope = "locations/global/metricsScopes/${var.project_id}"
  name          = each.value
}

###############################################################################
# Monitoring — Dashboard
###############################################################################
resource "google_monitoring_dashboard" "overview" {
  project = var.project_id
  dashboard_json = jsonencode({
    displayName = "Landing Zone Overview"
    gridLayout = {
      columns = 2
      widgets = [
        {
          title = "VM CPU Utilization"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
                  aggregation = {
                    alignmentPeriod  = "300s"
                    perSeriesAligner = "ALIGN_MEAN"
                  }
                }
              }
            }]
          }
        },
        {
          title = "VM Network Traffic"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"compute.googleapis.com/instance/network/received_bytes_count\""
                  aggregation = {
                    alignmentPeriod  = "300s"
                    perSeriesAligner = "ALIGN_RATE"
                  }
                }
              }
            }]
          }
        }
      ]
    }
  })
}

###############################################################################
# Monitoring — Alert Policy
###############################################################################
resource "google_monitoring_alert_policy" "high_cpu" {
  project      = var.project_id
  display_name = "High CPU Utilization Alert"
  combiner     = "OR"

  conditions {
    display_name = "CPU > 80% for 5 minutes"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }
}
