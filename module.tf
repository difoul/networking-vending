# VNet module call. Isolated in its own file so the (future) `version` line is
# an unambiguous target for the per-app/env version stamp done in CI before
# `terraform init` (ci/stamp-module-version.sh).
#
# PER-APP/ENV VERSIONING (wire in once the module is published):
#   1. Replace the local source with a registry or git source, e.g.
#        source  = "app.terraform.io/your-org/vnet/azurerm"
#        version = "1.0.0"  # baseline; CI overwrites from module_version
#      (for git:  source = "git::https://.../vnet.git//modules/vnet?ref=v1.0.0")
#   2. Set "module_version" in each config/<app>/<env>.json.
# The stamp script then fills the version per subscription. While the source is
# local (no version argument) the script is a no-op.
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
