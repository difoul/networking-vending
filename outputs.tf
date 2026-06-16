output "vnet_id" {
  description = "Resource ID of the spoke VNet."
  value       = module.vnet.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name => subnet ID."
  value       = module.vnet.subnet_ids
}

output "resource_group_name" {
  description = "Resource group holding the spoke network."
  value       = azurerm_resource_group.this.name
}
