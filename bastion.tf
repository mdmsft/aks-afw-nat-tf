resource "azurerm_public_ip" "bastion" {
  name                = "pip-${local.resource_suffix}-bas"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  ip_version          = "IPv4"
  zones               = local.availability_zones
}

resource "azurerm_bastion_host" "main" {
  name                   = "bas-${local.resource_suffix}"
  location               = azurerm_resource_group.main.location
  resource_group_name    = azurerm_resource_group.main.name
  sku                    = "Standard"
  scale_units            = var.bastion_scale_units
  copy_paste_enabled     = true
  file_copy_enabled      = true
  ip_connect_enabled     = true
  shareable_link_enabled = true
  tunneling_enabled      = true

  ip_configuration {
    name                 = "default"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}
