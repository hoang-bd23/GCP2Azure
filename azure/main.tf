###############################################################################
# Resource Group
###############################################################################
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

###############################################################################
# Virtual Network
###############################################################################
resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.gateway_subnet_cidr]
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.default_subnet_cidr]
}

###############################################################################
# VPN Gateway
###############################################################################
resource "azurerm_public_ip" "vpn_gw" {
  name                = "vpn-gateway-pip"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = "azure-vpn-gateway"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false
  bgp_enabled         = true

  bgp_settings {
    asn = var.azure_bgp_asn
    peering_addresses {
      ip_configuration_name = "default"
      apipa_addresses       = ["169.254.21.2"]
    }
  }

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = azurerm_public_ip.vpn_gw.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}

###############################################################################
# Local Network Gateways (GCP peers)
###############################################################################
resource "azurerm_local_network_gateway" "gcp" {
  count               = length(var.gcp_vpn_gateway_ips)
  name                = "gcp-lng-${count.index}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  gateway_address     = var.gcp_vpn_gateway_ips[count.index]
  address_space       = var.gcp_address_spaces

  bgp_settings {
    asn                 = var.gcp_bgp_asn
    bgp_peering_address = var.gcp_bgp_peer_ips[count.index]
  }
}

###############################################################################
# VPN Connections (IPsec/IKEv2)
###############################################################################
resource "azurerm_virtual_network_gateway_connection" "gcp" {
  count                      = length(var.gcp_vpn_gateway_ips)
  name                       = "vpn-to-gcp-${count.index}"
  location                   = data.azurerm_resource_group.this.location
  resource_group_name        = data.azurerm_resource_group.this.name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.gcp[count.index].id
  shared_key                 = var.vpn_shared_secret
  bgp_enabled                = true

  ipsec_policy {
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    dh_group         = "DHGroup14"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS14"
    sa_lifetime      = 3600
  }
}

###############################################################################
# Security rules for VPN test VM
###############################################################################
resource "azurerm_network_security_group" "test_vm" {
  name                = "test-vm-nsg"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  security_rule {
    name                       = "allow-icmp-from-gcp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = var.gcp_address_spaces
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh-from-gcp"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.gcp_address_spaces
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.test_vm.id
}

###############################################################################
# Test VM
###############################################################################
resource "azurerm_network_interface" "test_vm" {
  name                = "test-vm-nic"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.test_vm_private_ip
  }
}

resource "azurerm_linux_virtual_machine" "test" {
  name                            = "azure-test-vm"
  location                        = data.azurerm_resource_group.this.location
  resource_group_name             = data.azurerm_resource_group.this.name
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.test_vm.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
