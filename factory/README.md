# Repo factory

Terraform (`gitlabhq/gitlab` ~> 19.0) that stamps out **one GitLab project per
application**, each covering all four environments (dev/sim/uat/exp). New repos
are seeded from a **custom project template** and wired up with environments,
branch protection, and an approval gate.

## What it manages

Per app (`for_each` over `apps/*.json`):

- `gitlab_project` — created from the custom template (`use_custom_template`).
- `gitlab_branch_protection` — MR-only on `main` (nobody pushes directly).
- `gitlab_project_environment` ×4 — `dev`, `sim`, `uat`, `exp`.
- `gitlab_project_protected_environment` — approval gate on **uat + exp**
  (`approval_envs`); dev/sim auto-deploy.

Once at the group level (`parent_namespace_id`):

- `gitlab_group_variable` — the single **shared service principal**
  (`ARM_CLIENT_ID/SECRET`, `ARM_TENANT_ID`), masked + protected. Every app repo
  inherits these; the factory never sets per-repo or env-scoped credentials.

## Source of truth

One manifest per app under `apps/<app>.json`. The manifest is intentionally
small (just app-level metadata) — the per-env VNet config lives in each app
repo, seeded from the template and edited there.

## Prerequisite (one-time, manual)

The template project must be registered under a group designated for **custom
project templates** (Group → Settings → General → *Custom project templates*).
The provider does not manage that group setting; `template_name` +
`template_group_id` reference the already-registered template.

## Required variables

| Variable | Notes |
|---|---|
| `gitlab_token` | api scope; creates projects + sets group vars |
| `gitlab_base_url` | self-managed API base, empty = gitlab.com |
| `parent_namespace_id` | group the app repos (and group vars) live under |
| `template_name`, `template_group_id` | the registered custom template |
| `arm_tenant_id`, `arm_client_id`, `arm_client_secret` | shared SP |
| `approver_group_id` | who may approve gated (uat/exp) deploys |
