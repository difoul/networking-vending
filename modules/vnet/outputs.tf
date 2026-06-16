output "vnet_id" {
  description = "Resource ID of the spoke VNet."
  value       = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "Map of subnet name => subnet ID."
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}
