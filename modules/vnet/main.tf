terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # azurerm.hub is the hub-subscription provider, passed in by the caller.
      configuration_aliases = [azurerm.hub]
    }
  }
}

locals {
  # Parse the hub VNet resource ID to derive its resource group and name,
  # needed to create the hub-side peering.
  hub_parts = split("/", var.hub_vnet_id)
  hub_rg    = local.hub_parts[4]
  hub_name  = local.hub_parts[8]
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = { for s in var.subnets : s.name => s }

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.prefix]
}

# Spoke -> Hub (default/spoke provider)
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.this.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Hub -> Spoke (hub provider)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider = azurerm.hub

  name                         = "peer-to-${var.spoke_label}"
  resource_group_name          = local.hub_rg
  virtual_network_name         = local.hub_name
  remote_virtual_network_id    = azurerm_virtual_network.this.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}
