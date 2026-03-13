output "nat_id" {
  description = "Cloud NAT ID"
  value       = google_compute_router_nat.this.id
}

output "nat_name" {
  description = "Cloud NAT name"
  value       = google_compute_router_nat.this.name
}
