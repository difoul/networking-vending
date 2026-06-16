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

module "vnet" {
  source = "./modules/vnet"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  name                = "vnet-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = local.cfg.location
  address_space       = local.cfg.address_space
  subnets             = local.cfg.subnets
  dns_servers         = try(local.cfg.dns_servers, [])
  hub_vnet_id         = local.cfg.hub_vnet_id

  # Name of the spoke as seen from the hub side peering.
  spoke_label = local.name

  tags = try(local.cfg.tags, {})
}
