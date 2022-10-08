resource "azurerm_public_ip" "main" {
  name                    = "pip-${local.resource_suffix}"
  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 4
  ip_version              = "IPv4"
  zones                   = [var.zone]
}

resource "azurerm_firewall" "main" {
  name                = "afw-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  private_ip_ranges   = ["IANAPrivateRanges"]
  firewall_policy_id  = var.firewall_policy_id
  zones               = [var.zone]

  ip_configuration {
    name                 = "default"
    subnet_id            = azurerm_subnet.main.id
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

data "azurerm_monitor_diagnostic_categories" "main" {
  resource_id = azurerm_firewall.main.id
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                       = "Logs"
  target_resource_id         = azurerm_firewall.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.main.log_category_types

    content {
      category = log.value
      enabled  = true
    }
  }

  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}
