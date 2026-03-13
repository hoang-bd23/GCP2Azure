# Cloud Router
resource "google_compute_router" "this" {
  name    = var.router_name
  project = var.project_id
  region  = var.region
  network = var.network

  bgp {
    asn            = var.router_asn
    advertise_mode = "DEFAULT"
  }
}

# HA VPN Gateway
resource "google_compute_ha_vpn_gateway" "this" {
  name    = var.vpn_gateway_name
  project = var.project_id
  region  = var.region
  network = var.network
}

# External VPN Gateway (Azure peer)
resource "google_compute_external_vpn_gateway" "peer" {
  count = var.peer_external_gateway_name != null ? 1 : 0

  name            = var.peer_external_gateway_name
  project         = var.project_id
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"

  interface {
    id         = 0
    ip_address = var.peer_external_gateway_ip
  }
}

# VPN Tunnels
resource "google_compute_vpn_tunnel" "tunnels" {
  for_each = { for t in var.tunnels : t.name => t }

  name                            = each.value.name
  project                         = var.project_id
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.this.id
  vpn_gateway_interface           = each.value.vpn_gateway_interface
  peer_external_gateway           = var.peer_external_gateway_name != null ? google_compute_external_vpn_gateway.peer[0].id : null
  peer_gcp_gateway                = var.peer_gcp_gateway
  peer_external_gateway_interface = each.value.peer_external_gateway_interface
  shared_secret                   = var.shared_secret
  router                          = google_compute_router.this.id
  ike_version                     = 2
}

# Router Interfaces
resource "google_compute_router_interface" "interfaces" {
  for_each = { for t in var.tunnels : t.name => t }

  name       = "${each.value.name}-interface"
  project    = var.project_id
  region     = var.region
  router     = google_compute_router.this.name
  ip_range   = each.value.bgp_session_range
  vpn_tunnel = google_compute_vpn_tunnel.tunnels[each.key].name
}

# BGP Peers
resource "google_compute_router_peer" "peers" {
  for_each = { for t in var.tunnels : t.name => t }

  name                      = each.value.bgp_session_name
  project                   = var.project_id
  region                    = var.region
  router                    = google_compute_router.this.name
  peer_ip_address           = each.value.bgp_peer_ip
  peer_asn                  = var.peer_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.interfaces[each.key].name
}
