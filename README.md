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
  "location": "westeurope",
  "address_space": ["10.10.0.0/16"],
  "subnets": [{ "name": "app", "prefix": "10.10.1.0/24" }],
  "dns_servers": [],
  "hub_vnet_id": "/subscriptions/.../virtualNetworks/vnet-hub",
  "tags": { "app": "app1", "env": "dev" }
}
```

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
