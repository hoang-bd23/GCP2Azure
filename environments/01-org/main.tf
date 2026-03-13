###############################################################################
# Organization Folders
###############################################################################
resource "google_folder" "platform" {
  display_name = "Platform"
  parent       = "organizations/${var.org_id}"
}

resource "google_folder" "development" {
  display_name = "Development"
  parent       = "organizations/${var.org_id}"
}

resource "google_folder" "production" {
  display_name = "Production"
  parent       = "organizations/${var.org_id}"
}

###############################################################################
# Projects
###############################################################################
module "hub_project" {
  source = "../../modules/project"

  project_name    = "Hub Network"
  project_id      = var.hub_project_id
  folder_id       = google_folder.platform.name
  billing_account = var.billing_account

  activate_apis = [
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]

  labels = {
    environment = "shared"
    layer       = "platform"
  }
}

module "observability_project" {
  source = "../../modules/project"

  project_name    = "Central Observability"
  project_id      = var.observability_project_id
  folder_id       = google_folder.platform.name
  billing_account = var.billing_account

  activate_apis = [
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "bigquery.googleapis.com",
    "pubsub.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "securitycenter.googleapis.com",
    "cloudkms.googleapis.com",
  ]

  labels = {
    environment = "shared"
    layer       = "platform"
  }
}

module "dev_project" {
  source = "../../modules/project"

  project_name    = "Development"
  project_id      = var.dev_project_id
  folder_id       = google_folder.development.name
  billing_account = var.billing_account

  activate_apis = [
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]

  labels = {
    environment = "dev"
    layer       = "workload"
  }
}

module "prod_project" {
  source = "../../modules/project"

  project_name    = "Production"
  project_id      = var.prod_project_id
  folder_id       = google_folder.production.name
  billing_account = var.billing_account

  activate_apis = [
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]

  labels = {
    environment = "prod"
    layer       = "workload"
  }
}

###############################################################################
# Organization Policies
###############################################################################
resource "google_org_policy_policy" "restrict_vm_external_ip" {
  name   = "organizations/${var.org_id}/policies/compute.vmExternalIpAccess"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      deny_all = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "require_os_login" {
  name   = "organizations/${var.org_id}/policies/compute.requireOsLogin"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}
