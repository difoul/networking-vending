locals {
  # Source of truth: one manifest per application under apps/ (reusing the
  # JSON-config convention). The factory only needs the app-level list; the
  # per-env VNet config lives in each app repo (seeded from the template).
  apps = {
    for f in fileset("${path.module}/apps", "*.json") :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/apps/${f}"))
  }

  # One GitLab environment per (app, env).
  app_envs = {
    for pair in setproduct(keys(local.apps), var.environments) :
    "${pair[0]}:${pair[1]}" => { app = pair[0], env = pair[1] }
  }

  # Subset that requires manual approval before apply.
  gated_app_envs = {
    for k, v in local.app_envs : k => v if contains(var.approval_envs, v.env)
  }
}
