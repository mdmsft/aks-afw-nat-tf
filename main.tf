resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_suffix}"
  location = var.location

  tags = {
    project     = var.project
    environment = var.environment
    location    = var.location
    tool        = "terraform"
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

module "zone" {
  source                                    = "./modules/zone"
  for_each                                  = toset(local.availability_zones)
  resource_suffix                           = local.resource_suffix
  location                                  = var.location
  zone                                      = each.key
  address_space                             = local.address_spaces[each.key]
  remote_virtual_network_id                 = azurerm_virtual_network.main.id
  firewall_policy_id                        = azurerm_firewall_policy.main.id
  log_analytics_workspace_daily_quota_gb    = var.log_analytics_workspace_daily_quota_gb
  log_analytics_workspace_retention_in_days = var.log_analytics_workspace_retention_in_days
}

