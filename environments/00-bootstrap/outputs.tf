output "seed_project_id" {
  description = "Seed project ID (use this in other layers as bootstrap project)"
  value       = google_project.seed.project_id
}

output "tf_state_bucket" {
  description = "GCS bucket for Terraform state"
  value       = google_storage_bucket.tf_state.name
}

output "terraform_sa_email" {
  description = "Terraform service account email"
  value       = google_service_account.terraform.email
}

# Convenience: print all project IDs chosen for the landing zone
output "landing_zone_project_ids" {
  description = "All project IDs that will be created in subsequent layers"
  value = {
    seed          = var.seed_project_id
    hub_network   = var.hub_project_id
    observability = var.observability_project_id
    dev           = var.dev_project_id
    prod          = var.prod_project_id
  }
}
