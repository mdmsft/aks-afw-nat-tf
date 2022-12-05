resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 0)]
}

resource "azurerm_subnet" "workload" {
  name                 = "snet-vm"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 1)]
}

resource "azurerm_subnet" "services" {
  name                                          = "snet-pls"
  virtual_network_name                          = azurerm_virtual_network.main.name
  resource_group_name                           = azurerm_resource_group.main.name
  address_prefixes                              = [cidrsubnet(var.address_space, 8, 2)]
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "endpoints" {
  name                                      = "snet-pe"
  virtual_network_name                      = azurerm_virtual_network.main.name
  resource_group_name                       = azurerm_resource_group.main.name
  address_prefixes                          = [cidrsubnet(var.address_space, 8, 3)]
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_subnet" "cluster" {
  name                 = "snet-aks"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 4, 1)]
}

resource "azurerm_virtual_network_peering" "main" {
  for_each                     = toset(local.availability_zones)
  name                         = "peer-az-${each.key}"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.main.name
  remote_virtual_network_id    = module.zone[each.key].virtual_network_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true
}

resource "azurerm_network_security_group" "bastion" {
  name                = "nsg-${local.resource_suffix}-bas"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowInternetInbound"
    priority                   = 100
    protocol                   = "Tcp"
    access                     = "Allow"
    direction                  = "Inbound"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }

  security_rule {
    name                       = "AllowControlPlaneInbound"
    priority                   = 200
    protocol                   = "Tcp"
    access                     = "Allow"
    direction                  = "Inbound"
    source_address_prefix      = "GatewayManager"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }

  security_rule {
    name                       = "AllowHealthProbesInbound"
    priority                   = 300
    protocol                   = "Tcp"
    access                     = "Allow"
    direction                  = "Inbound"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }

  security_rule {
    name                       = "AllowDataPlaneInbound"
    priority                   = 400
    protocol                   = "Tcp"
    access                     = "Allow"
    direction                  = "Inbound"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges    = ["8080", "5701"]
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 1000
    protocol                   = "*"
    access                     = "Deny"
    direction                  = "Inbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name                       = "AllowSshRdpOutbound"
    priority                   = 100
    protocol                   = "Tcp"
    access                     = "Allow"
    direction                  = "Outbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["22", "3389"]
  }

  security_rule {
    name                       = "AllowCloudOutbound"
    priority                   = 200
    protocol                   = "Tcp"
    access                     = "Allow"
    direction                  = "Outbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "AzureCloud"
    destination_port_range     = "443"
  }

  security_rule {
    name                       = "AllowDataPlaneOutbound"
    priority                   = 300
    protocol                   = "Tcp"
    access                     = "Allow"
    direction                  = "Outbound"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["8080", "5701"]
  }

  security_rule {
    name                       = "AllowSessionCertificateValidationOutbound"
    priority                   = 400
    protocol                   = "Tcp"
    access                     = "Allow"
    direction                  = "Outbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "Internet"
    destination_port_range     = "80"
  }

  security_rule {
    name                       = "DenyAllOutbound"
    priority                   = 1000
    protocol                   = "*"
    access                     = "Deny"
    direction                  = "Outbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  network_security_group_id = azurerm_network_security_group.bastion.id
  subnet_id                 = azurerm_subnet.bastion.id
}

resource "azurerm_network_security_group" "cluster" {
  name                = "nsg-${local.resource_suffix}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "cluster" {
  network_security_group_id = azurerm_network_security_group.cluster.id
  subnet_id                 = azurerm_subnet.cluster.id
}

resource "azurerm_network_security_group" "workload" {
  name                = "nsg-${local.resource_suffix}-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  network_security_group_id = azurerm_network_security_group.workload.id
  subnet_id                 = azurerm_subnet.workload.id
}

resource "azurerm_route_table" "main" {
  name                = "rt-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_route" "internet_firewall" {
  name                   = "net-afw"
  resource_group_name    = azurerm_resource_group.main.name
  route_table_name       = azurerm_route_table.main.name
  address_prefix         = "0.0.0.0/0"
  next_hop_in_ip_address = azurerm_lb.firewall.frontend_ip_configuration.0.private_ip_address
  next_hop_type          = "VirtualAppliance"
}

# resource "azurerm_route" "firewall_internet" {
#   name                = "afw-www"
#   resource_group_name = azurerm_resource_group.main.name
#   route_table_name    = azurerm_route_table.main.name
#   address_prefix      = "${azurerm_public_ip.firewall["1"].ip_address}/32"
#   next_hop_type       = "Internet"
# }

resource "azurerm_subnet_route_table_association" "main" {
  subnet_id      = azurerm_subnet.cluster.id
  route_table_id = azurerm_route_table.main.id
}

resource "azurerm_private_dns_zone" "main" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each              = local.private_dns_zones
  name                  = azurerm_resource_group.main.name
  private_dns_zone_name = each.value
  resource_group_name   = azurerm_resource_group.main.name
  virtual_network_id    = azurerm_virtual_network.main.id

  depends_on = [
    azurerm_private_dns_zone.main
  ]
}

resource "azurerm_lb" "firewall" {
  name                = "lbi-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configuration {
    name                          = "default"
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
    subnet_id                     = azurerm_subnet.services.id
  }
}

resource "azurerm_lb_backend_address_pool" "firewall" {
  name            = "default"
  loadbalancer_id = azurerm_lb.firewall.id
}

resource "azurerm_lb_backend_address_pool_address" "firewall" {
  for_each                = toset(local.availability_zones)
  name                    = each.key
  backend_address_pool_id = azurerm_lb_backend_address_pool.firewall.id
  ip_address              = module.zone[each.key].private_endpoint_ip_address
  virtual_network_id      = azurerm_virtual_network.main.id
}

resource "azurerm_lb_rule" "firewall" {
  name                           = "default"
  loadbalancer_id                = azurerm_lb.firewall.id
  backend_address_pool_ids       = azurerm_lb_backend_address_pool.firewall[*].id
  backend_port                   = 0
  frontend_port                  = 0
  protocol                       = "All"
  frontend_ip_configuration_name = azurerm_lb.firewall.frontend_ip_configuration.0.name
}

resource "azurerm_private_link_service" "firewall" {
  name                                        = "pls-${local.resource_suffix}-afw"
  resource_group_name                         = azurerm_resource_group.main.name
  location                                    = azurerm_resource_group.main.location
  auto_approval_subscription_ids              = [data.azurerm_client_config.main.subscription_id]
  visibility_subscription_ids                 = [data.azurerm_client_config.main.subscription_id]
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.firewall.frontend_ip_configuration.0.id]

  nat_ip_configuration {
    name      = "primary"
    primary   = true
    subnet_id = azurerm_subnet.services.id
  }
}
