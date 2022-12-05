resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "main" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.main.address_space.0, 1, 0)]
}

resource "azurerm_subnet" "default" {
  name                                      = "snet-pe"
  virtual_network_name                      = azurerm_virtual_network.main.name
  resource_group_name                       = azurerm_resource_group.main.name
  address_prefixes                          = [cidrsubnet(azurerm_virtual_network.main.address_space.0, 1, 1)]
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_virtual_network_peering" "main" {
  name                         = reverse(split("/", var.remote_virtual_network_id)).0
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.main.name
  remote_virtual_network_id    = var.remote_virtual_network_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true
}

resource "azurerm_public_ip_prefix" "main" {
  name                = "ippre-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  ip_version          = "IPv4"
  prefix_length       = 28
  zones               = [var.zone]
}

resource "azurerm_nat_gateway" "main" {
  name                    = "ng-${local.resource_suffix}"
  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  idle_timeout_in_minutes = 4
  sku_name                = "Standard"
  zones                   = [var.zone]
}

resource "azurerm_route_table" "main" {
  name                = "rt-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_in_ip_address = azurerm_firewall.main.ip_configuration.0.private_ip_address
    next_hop_type          = "VirtualAppliance"
  }
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "main" {
  nat_gateway_id      = azurerm_nat_gateway.main.id
  public_ip_prefix_id = azurerm_public_ip_prefix.main.id
}

resource "azurerm_subnet_nat_gateway_association" "main" {
  subnet_id      = azurerm_subnet.main.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

resource "azurerm_subnet_route_table_association" "main" {
  subnet_id      = azurerm_subnet.default.id
  route_table_id = azurerm_route_table.main.id
}

resource "azurerm_private_endpoint" "main" {
  name                = "pe-${local.resource_suffix}-afw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.default.id

  private_service_connection {
    name                           = azurerm_firewall.main.name
    is_manual_connection           = false
    private_connection_resource_id = var.private_link_service_id
  }
}
