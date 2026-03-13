resource "google_project" "this" {
  name                = var.project_name
  project_id          = var.project_id
  org_id              = var.folder_id == null ? var.org_id : null
  folder_id           = var.folder_id
  billing_account     = var.billing_account
  auto_create_network = false
  deletion_policy     = "DELETE"
  labels              = var.labels
}

resource "google_project_service" "apis" {
  for_each = toset(var.activate_apis)

  project = google_project.this.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false
}
