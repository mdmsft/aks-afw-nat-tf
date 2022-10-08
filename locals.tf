locals {
  private_dns_zones = {
    registry = "privatelink.azurecr.io"
    vault    = "privatelink.vaultcore.azure.net"
    cluster  = "privatelink.${var.location}.azmk8s.io"
  }

  resource_suffix    = "${var.project}-${var.environment}-${var.region}"
  context_name       = "${var.project}-${var.environment}"
  availability_zones = [for i in range(1, 4) : tostring(i)]
  address_spaces     = { for az in local.availability_zones : az => "192.168.${az}.0/24" }
}
