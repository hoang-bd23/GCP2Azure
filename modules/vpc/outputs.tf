output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "The self link of the VPC network"
  value       = google_compute_network.this.self_link
}

output "subnets" {
  description = "Map of subnet details"
  value = {
    for name, subnet in google_compute_subnetwork.this : name => {
      id            = subnet.id
      name          = subnet.name
      ip_cidr_range = subnet.ip_cidr_range
      region        = subnet.region
      self_link     = subnet.self_link
    }
  }
}
