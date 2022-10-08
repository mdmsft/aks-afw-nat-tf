resource "azurerm_firewall_policy" "main" {
  name                     = "afwp-${local.resource_suffix}"
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  sku                      = "Standard"
  threat_intelligence_mode = "Alert"

  insights {
    enabled                            = true
    default_log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
    retention_in_days                  = var.log_analytics_workspace_retention_in_days
  }

  dns {
    proxy_enabled = true
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "default"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 200

  network_rule_collection {
    name     = "net"
    priority = 200
    action   = "Allow"

    rule {
      name                  = "ntp"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }

    rule {
      name             = "azure"
      protocols        = ["TCP"]
      source_addresses = ["*"]
      destination_addresses = [
        "AzureMonitor",
        "AzureContainerRegistry",
        "MicrosoftContainerRegistry",
        "AzureActiveDirectory"
      ]
      destination_ports = ["443"]
    }
  }

  application_rule_collection {
    name     = "app"
    priority = 300
    action   = "Allow"

    rule {
      name             = "azure"
      source_addresses = ["*"]
      destination_fqdns = [
        "*.hcp.${var.location}.azmk8s.io",
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        "management.azure.com",
        "login.microsoftonline.com",
        "packages.microsoft.com",
        "acs-mirror.azureedge.net",
        "dc.services.visualstudio.com",
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.monitoring.azure.com",
        "data.policy.core.windows.net",
        "store.policy.core.windows.net",
        "${var.location}.dp.kubernetesconfiguration.azure.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name             = "ubuntu"
      source_addresses = ["*"]
      destination_fqdns = [
        "archive.ubuntu.com",
        "security.ubuntu.com",
        "azure.archive.ubuntu.com",
        "changelogs.ubuntu.com",
        "motd.ubuntu.com"
      ]

      protocols {
        type = "Http"
        port = 80
      }

      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name             = "registry"
      source_addresses = ["*"]
      destination_fqdns = [
        "k8s.gcr.io",
        "storage.googleapis.com",
        "auth.docker.io",
        "registry-1.docker.io",
        "production.cloudflare.docker.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name             = "helm"
      source_addresses = ["*"]
      destination_fqdns = [
        "kubernetes.github.io",
        "github.com",
        "objects.githubusercontent.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }
  }
}
