# Networking vending

Deploys one VNet per subscription and peers it (both directions) to a central
hub. Configuration is driven by JSON files; state is GitLab-managed, one state
blob per subscription.

## How it works

- **Config** — `config/<app>/<env>.json`, one file per subscription. The file
  name pair `<app>/<env>` identifies the subscription and the state name
  (`<app>-<env>`). Envs: `dev`, `sim`, `uat`, `exp`.
- **Module** — `modules/vnet` creates the VNet, subnets, and the two peerings
  (`spoke_to_hub` via the spoke provider, `hub_to_spoke` via the aliased hub
  provider).
- **State** — GitLab-managed Terraform state (HTTP backend). One state name per
  subscription, set at `terraform init` in CI.
- **Pipeline** — parent/child. `generate` scans `config/*/*.json` and emits a
  child pipeline with a `plan` + `apply` job per subscription. Drop a new JSON
  file and its jobs appear automatically. `plan` runs on MRs and the default
  branch; `apply` is **manual** and only on the default branch.

## Config schema

```json
{
  "subscription_id": "<spoke subscription guid>",
  "module_version": "1.0.0",
  "location": "westeurope",
  "address_space": ["10.10.0.0/16"],
  "subnets": [{ "name": "app", "prefix": "10.10.1.0/24" }],
  "dns_servers": [],
  "hub_vnet_id": "/subscriptions/.../virtualNetworks/vnet-hub",
  "tags": { "app": "app1", "env": "dev" }
}
```

## Per-app/env module version

Terraform requires a module's `version` to be a static literal (it's resolved
at `terraform init`, before variables exist), so it can't be a variable. The
version therefore lives as data in each config's `module_version`, and CI
stamps it into the committed `module.tf` in place (`ci/stamp-module-version.sh`)
before `terraform init` - keeping `module.tf` reviewable and locally valid.

This is **inert today**: the module is a local source (`./modules/vnet`), which
has no `version` argument, so the stamp script is a no-op. To activate per-env
versioning once the module is published:

1. In `module.tf`, swap the local source for a registry/git source and add a
   baseline `version = "x.y.z"` line (see the comment in that file).
2. Keep `module_version` set per `config/<app>/<env>.json`.

The stamp script then fills the version per subscription, and fails the job if a
version line exists but `module_version` is missing.

## Required CI/CD variables

| Variable | Scope | Notes |
|---|---|---|
| `ARM_TENANT_ID` | shared | Entra tenant for the service principals |
| `<APP>_<ENV>_CLIENT_ID` | per subscription | SP app id, e.g. `APP1_DEV_CLIENT_ID` |
| `<APP>_<ENV>_CLIENT_SECRET` | per subscription | SP secret (masked + protected) |

The `<APP>_<ENV>` prefix is the app/env upper-cased with `.`/`-` turned into
`_` (e.g. `config/app1/dev.json` -> `APP1_DEV_CLIENT_ID`). The same SP also
creates the hub-side peering; the hub subscription is hardcoded in
`providers.tf`.

## Onboarding a new subscription

1. Add `config/<app>/<env>.json`.
2. Create its SP and add `<APP>_<ENV>_CLIENT_ID/SECRET` CI variables.
3. Grant that SP `Network Contributor` on both the spoke subscription and the
   hub VNet (the latter for the hub-side peering).
4. Open an MR — the plan job appears automatically.
