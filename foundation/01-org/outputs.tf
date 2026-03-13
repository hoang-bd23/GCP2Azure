output "platform_folder_id" {
  description = "Platform folder ID"
  value       = google_folder.platform.name
}

output "development_folder_id" {
  description = "Development folder ID"
  value       = google_folder.development.name
}

output "production_folder_id" {
  description = "Production folder ID"
  value       = google_folder.production.name
}

output "hub_project_id" {
  description = "Hub network project ID"
  value       = module.hub_project.project_id
}

output "observability_project_id" {
  description = "Central observability project ID"
  value       = module.observability_project.project_id
}

output "dev_project_id" {
  description = "Dev project ID"
  value       = module.dev_project.project_id
}

output "prod_project_id" {
  description = "Prod project ID"
  value       = module.prod_project.project_id
}
