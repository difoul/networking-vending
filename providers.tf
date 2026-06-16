terraform {
  required_version = ">= 1.9"

  # State is GitLab-managed (HTTP backend). All settings are injected at
  # `terraform init` time via -backend-config in CI, one state name per
  # subscription (<app>-<env>).
  backend "http" {}

  # NOTE: state-management demo branch.
  # The real implementation (main branch) configures the azurerm provider and
  # an aliased hub provider here. This branch deliberately uses no provider so
  # the team can validate the GitLab state backend without any Azure auth.
}
