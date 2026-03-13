output "network_self_link" {
  description = "VPC network self link"
  value       = module.vpc.network_self_link
}

output "network_name" {
  description = "VPC network name"
  value       = module.vpc.network_name
}

output "subnets" {
  description = "Map of subnet details"
  value       = module.vpc.subnets
}

output "vpn_gateway_ip_addresses" {
  description = "HA VPN Gateway external IPs (share with Azure admin)"
  value       = length(module.vpn) > 0 ? module.vpn[0].gateway_ip_addresses : []
}

output "router_name" {
  description = "Cloud Router name"
  value       = length(module.vpn) > 0 ? module.vpn[0].router_name : try(google_compute_router.nat_router[0].name, "")
}
