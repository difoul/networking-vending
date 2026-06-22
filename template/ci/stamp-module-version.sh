#!/usr/bin/env bash
#
# Stamps the per-app/env VNet module version into module.tf, in place, before
# `terraform init`. The version is resolved from config/<app>/<env>.json by the
# `generate` job (which has jq) and injected as the MODULE_VERSION CI variable,
# so the terraform image needs no jq. module.tf stays a real, reviewable,
# committed file with a baseline version that works for local
# `terraform validate`/`plan`.
#
# NO-OP when there is nothing to stamp:
#   - this demo branch has no module.tf (the VNet module is a dummy resource), or
#   - the module source is LOCAL (local modules have no `version` argument).
# It activates automatically once module.tf uses a registry/git source with a
# version line.
#
# Requires MODULE_VERSION in the environment (set per job by the pipeline).
set -euo pipefail

# Nothing to stamp without a module.tf that declares a version line.
if [ ! -f module.tf ] || ! grep -qE '^[[:space:]]*version[[:space:]]*=' module.tf; then
  echo "no versioned module.tf - skipping module version stamp."
  exit 0
fi

version="${MODULE_VERSION:-}"
if [ -z "$version" ]; then
  echo "ERROR: module.tf declares a version but MODULE_VERSION is unset (check config/${APP:-?}/${ENV:-?}.json has 'module_version')." >&2
  exit 1
fi

# Replace the version literal, preserving indentation and any trailing comment.
sed -i "s|^\([[:space:]]*version[[:space:]]*=[[:space:]]*\"\)[^\"]*\(\".*\)|\1${version}\2|" module.tf

# Fail loudly rather than silently deploy the baseline version.
grep -qF "version = \"${version}\"" module.tf \
  || { echo "ERROR: failed to stamp module version ${version} into module.tf" >&2; exit 1; }

echo "Stamped VNet module version ${version} (${APP}/${ENV}) into module.tf"
