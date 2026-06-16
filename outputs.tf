# DEMO outputs (state-management branch) - echo what was persisted to state.
output "placeholder" {
  description = "Config snapshot stored in this subscription's state."
  value       = terraform_data.vnet_placeholder.output
}

output "state_name" {
  description = "Logical state name for this subscription (<app>-<env>)."
  value       = local.name
}

output "module_version" {
  description = "Per-app/env module version read from config (demo of the data path)."
  value       = local.cfg.module_version
}
