locals {
  # Per-env VNet configuration, loaded from this repo's own config/<env>.json.
  cfg  = jsondecode(file("${path.module}/config/${var.env}.json"))
  app  = local.cfg.tags.app
  name = "${local.app}-${var.env}"
}

# DEMO PLACEHOLDER (repo-factory branch).
# Replaces module "vnet" with a no-op resource so the per-env GitLab state
# backend, the GitLab Environments model, and the protected-environment
# approval gate can all be validated without creating Azure resources. The
# parsed config is stored in state so each env keeps distinct state content.
resource "terraform_data" "vnet_placeholder" {
  input = {
    vnet_name       = "vnet-${local.name}"
    subscription_id = local.cfg.subscription_id
    module_version  = local.cfg.module_version
    location        = local.cfg.location
    address_space   = local.cfg.address_space
    subnets         = [for s in local.cfg.subnets : s.name]
    hub_vnet_id     = local.cfg.hub_vnet_id
  }
}
