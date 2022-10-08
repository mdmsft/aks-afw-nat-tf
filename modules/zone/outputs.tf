output "virtual_network_id" {
  value = azurerm_virtual_network.main.id
}

output "firewall_private_ip_address" {
  value = azurerm_firewall.main.ip_configuration.0.private_ip_address
}
