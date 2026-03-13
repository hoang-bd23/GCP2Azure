output "external_ip" {
  description = "The external IP address of the load balancer"
  value       = google_compute_global_address.this.address
}

output "backend_service_id" {
  description = "The backend service ID"
  value       = google_compute_backend_service.this.id
}

output "url_map_id" {
  description = "The URL map ID"
  value       = google_compute_url_map.this.id
}
