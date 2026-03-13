output "azure_vpn_gateway_public_ip" {
  description = "Azure VPN Gateway public IP (share with GCP admin)"
  value       = azurerm_public_ip.vpn_gw.ip_address
}

output "azure_vnet_address_space" {
  description = "Azure VNet address space"
  value       = azurerm_virtual_network.this.address_space
}

output "test_vm_private_ip" {
  description = "Azure test VM private IP"
  value       = azurerm_network_interface.test_vm.private_ip_address
}

output "azure_vpn_gateway_bgp_asn" {
  description = "Azure VPN Gateway BGP ASN"
  value       = var.azure_bgp_asn
}

output "gcp_local_network_gateways" {
  description = "Local network gateways configured for GCP peers"
  value = [for i in range(length(azurerm_local_network_gateway.gcp)) : {
    name            = azurerm_local_network_gateway.gcp[i].name
    gcp_gateway_ip  = azurerm_local_network_gateway.gcp[i].gateway_address
    gcp_bgp_peer_ip = azurerm_local_network_gateway.gcp[i].bgp_settings[0].bgp_peering_address
  }]
}
