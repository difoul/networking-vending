terraform {
  required_version = ">= 1.9"

  # State is GitLab-managed (HTTP backend), one state name per environment,
  # set at `terraform init` in CI. Namespaced within this app's project, so the
  # state name is simply the env (dev/sim/uat/exp).
  backend "http" {}

  # DEMO TEMPLATE: no provider on purpose so the design can be validated without
  # Azure auth. The production template configures the azurerm provider (spoke)
  # plus an aliased hub provider, authenticating with the shared service
  # principal inherited from the GROUP CI/CD variables (ARM_CLIENT_ID/SECRET,
  # ARM_TENANT_ID) and targeting local.cfg.subscription_id.
}
