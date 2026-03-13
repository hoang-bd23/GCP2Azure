###############################################################################
# KMS Key Ring & Keys
###############################################################################
resource "google_kms_key_ring" "this" {
  name     = var.kms_key_ring_name
  project  = var.project_id
  location = var.region
}

resource "google_kms_crypto_key" "keys" {
  for_each = toset(var.kms_keys)

  name            = each.value
  key_ring        = google_kms_key_ring.this.id
  rotation_period = var.kms_rotation_period
  purpose         = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Organization IAM Bindings
###############################################################################
resource "google_organization_iam_member" "bindings" {
  for_each = { for idx, b in var.org_iam_bindings : "${b.role}-${b.member}" => b }

  org_id = var.org_id
  role   = each.value.role
  member = each.value.member
}

###############################################################################
# Security Command Center Notification Config
###############################################################################
resource "google_scc_notification_config" "default" {
  count = var.scc_notification_topic != "" ? 1 : 0

  config_id    = "landing-zone-scc-notifications"
  organization = var.org_id
  pubsub_topic = var.scc_notification_topic

  streaming_config {
    filter = "severity = \"HIGH\" OR severity = \"CRITICAL\""
  }
}
