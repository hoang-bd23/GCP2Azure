variable "hub_project_id" {
  description = "Hub network project ID"
  type        = string
}

variable "dev_project_id" {
  description = "Dev service project ID"
  type        = string
}

variable "prod_project_id" {
  description = "Prod service project ID"
  type        = string
}

variable "region" {
  description = "Primary GCP region"
  type        = string
  default     = "asia-southeast1"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "hub-vpc"
}

variable "dev_subnet_cidr" {
  description = "CIDR for Dev subnet"
  type        = string
  default     = "10.10.0.0/16"
}

variable "prod_subnet_cidr" {
  description = "CIDR for Prod subnet"
  type        = string
  default     = "10.20.0.0/16"
}

# VPN (optional — set azure_vpn_gateway_ip to enable)
variable "azure_vpn_gateway_ip" {
  description = "Public IP of the Azure VPN Gateway (leave empty to skip VPN)"
  type        = string
  default     = ""
}

variable "azure_bgp_asn" {
  description = "BGP ASN of the Azure VPN Gateway"
  type        = number
  default     = 65515
}

variable "vpn_shared_secret" {
  description = "Pre-shared key for IPsec VPN tunnel"
  type        = string
  sensitive   = true
  default     = ""
}

variable "router_asn" {
  description = "BGP ASN for Cloud Router"
  type        = number
  default     = 65001
}

