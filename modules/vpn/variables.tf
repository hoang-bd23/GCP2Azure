variable "project_id" {
  description = "Project ID for VPN resources"
  type        = string
}

variable "region" {
  description = "Region for VPN gateway"
  type        = string
}

variable "network" {
  description = "VPC network self link"
  type        = string
}

variable "vpn_gateway_name" {
  description = "Name of the HA VPN gateway"
  type        = string
}

variable "router_name" {
  description = "Name of the Cloud Router"
  type        = string
}

variable "router_asn" {
  description = "BGP ASN for Cloud Router"
  type        = number
  default     = 65001
}

variable "peer_gcp_gateway" {
  description = "Self link of peer HA VPN gateway (for GCP-to-GCP). Mutually exclusive with peer_external_gateway"
  type        = string
  default     = null
}

variable "peer_external_gateway_name" {
  description = "Name of the external VPN gateway (for Azure/AWS)"
  type        = string
  default     = null
}

variable "peer_external_gateway_ip" {
  description = "Public IP of the external VPN gateway"
  type        = string
  default     = null
}

variable "peer_asn" {
  description = "BGP ASN of the peer"
  type        = number
  default     = 65515
}

variable "shared_secret" {
  description = "Pre-shared key for IPsec tunnel"
  type        = string
  sensitive   = true
}

variable "tunnels" {
  description = "List of VPN tunnel configurations"
  type = list(object({
    name                            = string
    vpn_gateway_interface           = number
    peer_external_gateway_interface = optional(number)
    bgp_session_name                = string
    bgp_peer_ip                     = string
    bgp_session_range               = string
  }))
  default = [
    {
      name                            = "tunnel-0"
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = 0
      bgp_session_name                = "bgp-session-0"
      bgp_peer_ip                     = "169.254.0.2"
      bgp_session_range               = "169.254.0.1/30"
    },
    {
      name                            = "tunnel-1"
      vpn_gateway_interface           = 1
      peer_external_gateway_interface = 0
      bgp_session_name                = "bgp-session-1"
      bgp_peer_ip                     = "169.254.1.2"
      bgp_session_range               = "169.254.1.1/30"
    }
  ]
}
