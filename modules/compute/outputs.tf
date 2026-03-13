output "instance_id" {
  description = "Instance ID"
  value       = google_compute_instance.this.id
}

output "instance_name" {
  description = "Instance name"
  value       = google_compute_instance.this.name
}

output "internal_ip" {
  description = "Internal IP address"
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "instance_group" {
  description = "Instance group self link"
  value       = google_compute_instance_group.this.self_link
}

output "instance_self_link" {
  description = "Instance self link"
  value       = google_compute_instance.this.self_link
}
