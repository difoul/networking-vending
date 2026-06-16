#!/usr/bin/env bash
#
# Stamps the per-app/env VNet module version into module.tf, in place, before
# `terraform init`. Versions live as data in config/<app>/<env>.json
# ("module_version"); module.tf stays a real, reviewable, committed file with a
# baseline version that works for local `terraform validate`/`plan`.
#
# NO-OP while the module source is LOCAL: local modules have no `version`
# argument, so there is no line to stamp and this exits cleanly. It activates
# automatically once module.tf uses a registry/git source with a version line.
#
# Requires APP and ENV in the environment (set per job by the pipeline).
set -euo pipefail

config="config/${APP}/${ENV}.json"

# Nothing to do while the module is local (no version argument present).
if ! grep -qE '^[[:space:]]*version[[:space:]]*=' module.tf; then
  echo "module.tf has no version line (local module) - skipping version stamp."
  exit 0
fi

version="$(jq -r '.module_version // empty' "$config")"
if [ -z "$version" ]; then
  echo "ERROR: module.tf declares a version but ${config} has no 'module_version'." >&2
  exit 1
fi

# Replace the version literal, preserving indentation and any trailing comment.
sed -i "s|^\([[:space:]]*version[[:space:]]*=[[:space:]]*\"\)[^\"]*\(\".*\)|\1${version}\2|" module.tf

# Fail loudly rather than silently deploy the baseline version.
grep -qF "version = \"${version}\"" module.tf \
  || { echo "ERROR: failed to stamp module version ${version} into module.tf" >&2; exit 1; }

echo "Stamped VNet module version ${version} (${APP}/${ENV}) into module.tf"
