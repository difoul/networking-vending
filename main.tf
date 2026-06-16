locals {
  # VNet configuration is loaded from a per-subscription JSON file.
  cfg = jsondecode(file("${path.module}/config/${var.app}/${var.env}.json"))

  name = "${var.app}-${var.env}"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}-network"
  location = local.cfg.location
  tags     = try(local.cfg.tags, {})
}
