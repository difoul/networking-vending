terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.77"
    }
  }

  # State is GitLab-managed (HTTP backend). All settings are injected at
  # `terraform init` time via -backend-config in CI, one state name per
  # subscription (<app>-<env>).
  backend "http" {}
}

# Default provider = the spoke subscription.
# Credentials come from ARM_* environment variables set per matrix entry in CI
# (per app/env service principal). ARM_SUBSCRIPTION_ID points at the spoke sub.
provider "azurerm" {
  features {}
}

# Aliased provider = the hub subscription, used only for the hub->spoke peering.
# Uses the same service principal as the spoke (ARM_CLIENT_ID / ARM_CLIENT_SECRET
# / ARM_TENANT_ID env vars are inherited); only the subscription differs and is
# hardcoded here since the hub is a single, fixed subscription.
provider "azurerm" {
  alias = "hub"

  features {}

  subscription_id = "ffffffff-ffff-ffff-ffff-ffffffffffff"
}
