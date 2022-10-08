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
  address_prefixes     = azurerm_virtual_network.main.address_space
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

resource "azurerm_nat_gateway_public_ip_prefix_association" "main" {
  nat_gateway_id      = azurerm_nat_gateway.main.id
  public_ip_prefix_id = azurerm_public_ip_prefix.main.id
}

resource "azurerm_subnet_nat_gateway_association" "main" {
  subnet_id      = azurerm_subnet.main.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}
