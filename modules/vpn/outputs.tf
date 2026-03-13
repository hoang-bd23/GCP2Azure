output "gateway_id" {
  description = "HA VPN Gateway ID"
  value       = google_compute_ha_vpn_gateway.this.id
}

output "gateway_ip_addresses" {
  description = "HA VPN Gateway IP addresses"
  value       = google_compute_ha_vpn_gateway.this.vpn_interfaces
}

output "router_name" {
  description = "Cloud Router name"
  value       = google_compute_router.this.name
}

output "router_id" {
  description = "Cloud Router ID"
  value       = google_compute_router.this.id
}

output "tunnel_names" {
  description = "VPN tunnel names"
  value       = [for t in google_compute_vpn_tunnel.tunnels : t.name]
}
