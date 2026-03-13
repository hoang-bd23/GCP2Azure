variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "azure_region" {
  description = "Azure region"
  type        = string
  default     = "southeastasia"
}

variable "resource_group_name" {
  description = "Azure Resource Group name"
  type        = string
  default     = "rg-hybrid-vpn"
}

variable "vnet_name" {
  description = "Azure VNet name"
  type        = string
  default     = "azure-vnet"
}

variable "vnet_address_space" {
  description = "Azure VNet address space"
  type        = list(string)
  default     = ["10.30.0.0/16"]
}

variable "gateway_subnet_cidr" {
  description = "GatewaySubnet CIDR (required for VPN Gateway)"
  type        = string
  default     = "10.30.255.0/27"
}

variable "default_subnet_cidr" {
  description = "Default subnet CIDR for test VMs"
  type        = string
  default     = "10.30.1.0/24"
}

variable "gcp_vpn_gateway_ips" {
  description = "Public IPs of GCP HA VPN Gateway interfaces"
  type        = list(string)
}

variable "gcp_address_spaces" {
  description = "GCP address spaces to route via VPN"
  type        = list(string)
  default     = ["10.10.0.0/16", "10.20.0.0/16"]
}

variable "vpn_shared_secret" {
  description = "Pre-shared key for IPsec VPN tunnel"
  type        = string
  sensitive   = true
}

variable "gcp_bgp_asn" {
  description = "BGP ASN of GCP Cloud Router"
  type        = number
  default     = 65001
}

variable "azure_bgp_asn" {
  description = "BGP ASN of Azure VPN Gateway"
  type        = number
  default     = 65010
}

variable "gcp_bgp_peer_ips" {
  description = "GCP Cloud Router BGP peer IPs per tunnel"
  type        = list(string)
  default     = ["169.254.21.1", "169.254.22.1"]
}

variable "test_vm_private_ip" {
  description = "Static private IP for the Azure test VM"
  type        = string
  default     = "10.30.1.5"
}
