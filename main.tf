locals {
  # VNet configuration is loaded from a per-subscription JSON file.
  cfg = jsondecode(file("${path.module}/config/${var.app}/${var.env}.json"))

  name = "${var.app}-${var.env}"
}

# DEMO PLACEHOLDER (state-management branch).
# Replaces module "vnet" with a no-op resource so we can validate the
# per-subscription GitLab state backend (init / lock / plan / apply / state
# isolation) without creating Azure resources. The parsed config is stored in
# state so you can see each subscription keeps its own distinct state content.
resource "terraform_data" "vnet_placeholder" {
  input = {
    vnet_name       = "vnet-${local.name}"
    subscription_id = local.cfg.subscription_id
    # Demonstrates the per-app/env module version flowing from JSON into state.
    # On the real branch this value is stamped into module.tf's `version` line
    # by ci/stamp-module-version.sh before init.
    module_version = local.cfg.module_version
    location       = local.cfg.location
    address_space  = local.cfg.address_space
    subnets        = [for s in local.cfg.subnets : s.name]
    hub_vnet_id    = local.cfg.hub_vnet_id
  }
}
