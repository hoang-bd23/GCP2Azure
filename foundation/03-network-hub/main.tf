###############################################################################
# Shared VPC Host Project
###############################################################################
resource "google_compute_shared_vpc_host_project" "hub" {
  project = var.hub_project_id
}

resource "google_compute_shared_vpc_service_project" "dev" {
  host_project    = google_compute_shared_vpc_host_project.hub.project
  service_project = var.dev_project_id
}

resource "google_compute_shared_vpc_service_project" "prod" {
  host_project    = google_compute_shared_vpc_host_project.hub.project
  service_project = var.prod_project_id
}

###############################################################################
# VPC & Subnets
###############################################################################
module "vpc" {
  source = "../../modules/vpc"

  project_id   = var.hub_project_id
  network_name = var.network_name

  subnets = [
    {
      name          = "dev-subnet"
      ip_cidr_range = var.dev_subnet_cidr
      region        = var.region
    },
    {
      name          = "prod-subnet"
      ip_cidr_range = var.prod_subnet_cidr
      region        = var.region
    },
  ]
}

###############################################################################
# HA VPN + Cloud Router + BGP (to Azure) — OPTIONAL
###############################################################################
module "vpn" {
  source = "../../modules/vpn"
  count  = var.azure_vpn_gateway_ip != "" ? 1 : 0

  project_id       = var.hub_project_id
  region           = var.region
  network          = module.vpc.network_self_link
  vpn_gateway_name = "ha-vpn-to-azure"
  router_name      = "hub-cloud-router"
  router_asn       = var.router_asn
  shared_secret    = var.vpn_shared_secret

  peer_external_gateway_name = "azure-vpn-gateway"
  peer_external_gateway_ip   = var.azure_vpn_gateway_ip
  peer_asn                   = var.azure_bgp_asn

  tunnels = [
    {
      name                            = "tunnel-to-azure-0"
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = 0
      bgp_session_name                = "bgp-azure-0"
      bgp_peer_ip                     = "10.30.255.30"
      bgp_session_range               = "169.254.21.1/30"
    },
    {
      name                            = "tunnel-to-azure-1"
      vpn_gateway_interface           = 1
      peer_external_gateway_interface = 0
      bgp_session_name                = "bgp-azure-1"
      bgp_peer_ip                     = "10.30.255.30"
      bgp_session_range               = "169.254.22.1/30"
    },
  ]
}

###############################################################################
# Cloud Router for NAT (standalone when VPN is disabled)
###############################################################################
resource "google_compute_router" "nat_router" {
  count   = var.azure_vpn_gateway_ip == "" ? 1 : 0
  name    = "hub-nat-router"
  project = var.hub_project_id
  region  = var.region
  network = module.vpc.network_self_link
}

###############################################################################
# Cloud NAT
###############################################################################
module "nat" {
  source = "../../modules/nat"

  project_id  = var.hub_project_id
  region      = var.region
  router_name = var.azure_vpn_gateway_ip != "" ? module.vpn[0].router_name : google_compute_router.nat_router[0].name
  nat_name    = "hub-cloud-nat"
}

###############################################################################
# Firewall Rules
###############################################################################
module "firewall" {
  source = "../../modules/firewall"

  project_id = var.hub_project_id
  network    = module.vpc.network_self_link

  rules = [
    {
      name        = "allow-internal"
      description = "Allow all internal traffic between subnets"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["10.10.0.0/16", "10.20.0.0/16"]
      allow = [
        { protocol = "tcp" },
        { protocol = "udp" },
        { protocol = "icmp" },
      ]
    },
    {
      name        = "allow-azure-vpn"
      description = "Allow traffic from Azure VNet via VPN"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["10.30.0.0/16"]
      allow = [
        { protocol = "tcp" },
        { protocol = "udp" },
        { protocol = "icmp" },
      ]
    },
    {
      name        = "allow-health-checks"
      description = "Allow GCP health check ranges for LB"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["35.191.0.0/16", "130.211.0.0/22"]
      allow = [
        { protocol = "tcp", ports = ["80", "443"] },
      ]
      target_tags = ["http-server"]
    },
    {
      name        = "allow-iap-ssh"
      description = "Allow SSH via IAP"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["35.235.240.0/20"]
      allow = [
        { protocol = "tcp", ports = ["22"] },
      ]
    },
    {
      name        = "deny-all-ingress"
      description = "Default deny all ingress"
      direction   = "INGRESS"
      priority    = 65534
      ranges      = ["0.0.0.0/0"]
      deny = [
        { protocol = "all" },
      ]
    },
  ]
}

###############################################################################
# Note: Load Balancer is deployed per service project (05-env-dev, 06-env-prod)
# because GCP does not allow cross-project instance group backends.
###############################################################################
