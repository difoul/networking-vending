#!/usr/bin/env bash
#
# Scans config/<app>/<env>.json and emits a child pipeline with one
# plan + apply job per subscription (<app>-<env>). Adding a new JSON file
# automatically adds its jobs - no YAML edits required.
#
# Per app/env service-principal credentials are read from CI/CD variables named
# <APP>_<ENV>_CLIENT_ID and <APP>_<ENV>_CLIENT_SECRET (e.g. APP1_DEV_CLIENT_ID).
# The same SP is used for the hub->spoke peering (it just targets a different,
# hardcoded subscription via the aliased provider).
#
set -euo pipefail

# ----- Shared base job (YAML anchor reused by every generated job) -----------
cat <<'HEADER'
stages:
  - plan
  - apply

.terraform:
  image:
    name: hashicorp/terraform:1.14
    entrypoint: [""]
  before_script:
    # Service principal credentials. ARM_TENANT_ID is a shared CI variable;
    # client id/secret are per-app/env. The aliased hub provider inherits these.
    - export ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
    - eval "export ARM_CLIENT_ID=\"\$${VARPREFIX}_CLIENT_ID\""
    - eval "export ARM_CLIENT_SECRET=\"\$${VARPREFIX}_CLIENT_SECRET\""
    # GitLab-managed state, one state name per subscription.
    - |
      terraform init \
        -backend-config="address=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${STATE_NAME}" \
        -backend-config="lock_address=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${STATE_NAME}/lock" \
        -backend-config="unlock_address=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${STATE_NAME}/lock" \
        -backend-config="username=gitlab-ci-token" \
        -backend-config="password=${CI_JOB_TOKEN}" \
        -backend-config="lock_method=POST" \
        -backend-config="unlock_method=DELETE" \
        -backend-config="retry_wait_min=5"
HEADER

# ----- One plan + apply job per config file ----------------------------------
shopt -s nullglob
for f in config/*/*.json; do
  app="$(basename "$(dirname "$f")")"
  env="$(basename "$f" .json)"
  sub_id="$(jq -r '.subscription_id' "$f")"
  state="${app}-${env}"
  varprefix="$(printf '%s_%s' "$app" "$env" | tr '[:lower:].-' '[:upper:]__')"

  cat <<EOF

plan:${state}:
  extends: .terraform
  stage: plan
  variables:
    APP: "${app}"
    ENV: "${env}"
    STATE_NAME: "${state}"
    SUBSCRIPTION_ID: "${sub_id}"
    VARPREFIX: "${varprefix}"
  script:
    - terraform plan -input=false -var="app=\$APP" -var="env=\$ENV" -out=plan.cache
  artifacts:
    paths: [plan.cache]
    expire_in: 1 day
  # Only run when this subscription's config changed, or when shared
  # Terraform/module/pipeline code changed (which affects every subscription).
  # web / RUN_ALL bypass change-detection (forwarded from the parent pipeline).
  rules:
    - if: '\$PIPELINE_SOURCE == "web"'
    - if: '\$RUN_ALL == "true"'
    - if: '\$PIPELINE_SOURCE == "merge_request_event"'
      changes: &changes-${state}
        - "${f}"
        - ".gitlab-ci.yml"
        - "ci/**/*"
        - "*.tf"
        - "modules/**/*"
    - if: '\$TARGET_BRANCH == \$CI_DEFAULT_BRANCH'
      changes: *changes-${state}

apply:${state}:
  extends: .terraform
  stage: apply
  needs: ["plan:${state}"]
  variables:
    APP: "${app}"
    ENV: "${env}"
    STATE_NAME: "${state}"
    SUBSCRIPTION_ID: "${sub_id}"
    VARPREFIX: "${varprefix}"
  environment:
    name: ${state}
  script:
    - terraform apply -input=false plan.cache
  # Apply is always manual and only on the default branch (TARGET_BRANCH is
  # empty on MR pipelines, so those never match).
  rules:
    - if: '\$TARGET_BRANCH != \$CI_DEFAULT_BRANCH'
      when: never
    - if: '\$PIPELINE_SOURCE == "web" || \$RUN_ALL == "true"'
      when: manual
    - changes: *changes-${state}
      when: manual
EOF
done
