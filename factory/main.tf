# One project per app, seeded from the registered custom project template.
resource "gitlab_project" "app" {
  for_each = local.apps

  name           = "networking-vending-${each.key}"
  namespace_id   = var.parent_namespace_id
  description    = try(each.value.description, "Networking vending spoke for ${each.key}")
  default_branch = "main"

  # Seed content from the custom project template (group must be registered).
  use_custom_template             = true
  template_name                   = var.template_name
  group_with_project_templates_id = var.template_group_id

  # MR hygiene.
  only_allow_merge_if_pipeline_succeeds = true
  merge_method                          = "ff"
}

# Protect the default branch: merge via MR only, nobody pushes directly.
resource "gitlab_branch_protection" "main" {
  for_each = local.apps

  project            = gitlab_project.app[each.key].id
  branch             = "main"
  push_access_level  = "no one"
  merge_access_level = "maintainer"
}

# A GitLab environment per (app, env). The template's apply jobs deploy into
# these via `environment: name: <env>`.
resource "gitlab_project_environment" "env" {
  for_each = local.app_envs

  project = gitlab_project.app[each.value.app].id
  name    = each.value.env
}

# Approval gate on the protected environments (uat + exp by default). The apply
# job pauses until a member of approver_group_id approves the deployment.
resource "gitlab_project_protected_environment" "gated" {
  for_each = local.gated_app_envs

  project     = gitlab_project.app[each.value.app].id
  environment = gitlab_project_environment.env[each.key].name

  deploy_access_levels_attribute = [
    {
      access_level = "maintainer"
    }
  ]

  approval_rules = [
    {
      group_id           = var.approver_group_id
      required_approvals = 1
    }
  ]
}
