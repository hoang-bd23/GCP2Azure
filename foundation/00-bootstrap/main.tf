###############################################################################
# 1. Seed Project (created from scratch using org-level credentials)
###############################################################################
resource "google_project" "seed" {
  name                = var.seed_project_name
  project_id          = var.seed_project_id
  org_id              = var.org_id
  billing_account     = var.billing_account
  auto_create_network = false
  deletion_policy     = "DELETE"

  labels = {
    purpose = "bootstrap"
    managed = "terraform"
  }
}

# Enable required APIs on the seed project
resource "google_project_service" "bootstrap_apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "serviceusage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "storage.googleapis.com",
  ])

  project = google_project.seed.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false
}

###############################################################################
# 2. GCS Bucket for Terraform Remote State
###############################################################################
resource "google_storage_bucket" "tf_state" {
  name          = var.tf_state_bucket_name
  project       = google_project.seed.project_id
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.bootstrap_apis]
}

###############################################################################
# 3. Terraform Service Account
###############################################################################
resource "google_service_account" "terraform" {
  account_id   = var.tf_sa_name
  display_name = "Terraform Runner Service Account"
  project      = google_project.seed.project_id

  depends_on = [google_project_service.bootstrap_apis]
}

# Grant org-level roles to Terraform SA
resource "google_organization_iam_member" "tf_sa_roles" {
  for_each = toset([
    "roles/resourcemanager.organizationAdmin",
    "roles/resourcemanager.folderAdmin",
    "roles/resourcemanager.projectCreator",
    "roles/billing.user",
    "roles/compute.xpnAdmin",
    "roles/iam.organizationRoleAdmin",
    "roles/logging.configWriter",
    "roles/securitycenter.admin",
  ])

  org_id = var.org_id
  role   = each.value
  member = "serviceAccount:${google_service_account.terraform.email}"
}
