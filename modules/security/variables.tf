variable "project_id" {
  description = "Project ID for security resources"
  type        = string
}

variable "org_id" {
  description = "Organization ID"
  type        = string
}

variable "region" {
  description = "Region for KMS key ring"
  type        = string
}

variable "kms_key_ring_name" {
  description = "Name of the KMS key ring"
  type        = string
  default     = "landing-zone-keyring"
}

variable "kms_keys" {
  description = "List of KMS key names to create"
  type        = list(string)
  default     = ["default-key"]
}

variable "kms_rotation_period" {
  description = "Rotation period for KMS keys (e.g., 7776000s = 90 days)"
  type        = string
  default     = "7776000s"
}

variable "org_iam_bindings" {
  description = "Org-level IAM bindings"
  type = list(object({
    role   = string
    member = string
  }))
  default = []
}

variable "scc_notification_topic" {
  description = "Pub/Sub topic for SCC notifications"
  type        = string
  default     = ""
}
