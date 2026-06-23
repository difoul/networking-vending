# Networking vending — app template

The content every app repo receives (registered as a GitLab **custom project
template**). One repo = one application; the four environments live side by side
as `config/<env>.json`.

> **Demo branch:** the VNet module is a `terraform_data` placeholder so the
> design (per-env state, GitLab Environments, the approval gate) can be
> validated without Azure. The production template configures the `azurerm`
> provider (spoke + aliased hub) authenticating with the group-level shared
> service principal and targeting `config/<env>.json`'s `subscription_id`.

## Layout

- `config/{dev,sim,uat,exp}.json` — per-env VNet config (edited in this repo).
- `main.tf` — loads `config/$env.json`; stores parsed config in state.
- `.gitlab-ci.yml` — `plan` + `apply` per env via **GitLab Environments**.
  `plan` on MRs + default; `apply` on default. uat/exp are protected
  environments (set by the factory) → apply waits for approval; dev/sim
  auto-deploy. State name = env.

## Which envs run (`DEPLOY_ENV`)

- **Auto (default):** an env runs only when its own `config/<env>.json` changes;
  a shared change (`*.tf`, `ci/**`, `.gitlab-ci.yml`) plans **all** envs.
- **Force one env / all:** in *Run pipeline*, set `DEPLOY_ENV=<env>` (or `all`)
  to run regardless of the diff.

Trunk-based: MRs target `main` (plan only); merging to `main` applies (dev/sim
auto, uat/exp gated). The same commit promotes across all envs.

## Onboarding a new env

Edit/add `config/<env>.json` (env must be one of dev/sim/uat/exp) and open an
MR — the matching `plan:<env>` runs automatically.
