#!/usr/bin/env bash
#
# Scans config/<app>/<env>.json and emits a child pipeline with one
# plan + apply job per subscription (<app>-<env>). Adding a new JSON file
# automatically adds its jobs - no YAML edits required.
#
# DEMO (state-management branch): jobs need no Azure credentials; they only
# exercise the per-subscription GitLab state backend. The real branch resolves
# per app/env service-principal credentials from <APP>_<ENV>_CLIENT_ID/SECRET.
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
    # DEMO: no Azure auth needed - we only exercise the GitLab state backend.
    # CI_JOB_TOKEN is provided automatically. (The real branch exports ARM_*
    # service-principal credentials here.)
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
  rules:
    - if: '\$PIPELINE_SOURCE == "merge_request_event"'
      changes: &changes-${state}
        - "${f}"
        - "*.tf"
        - "modules/**/*"
        - "ci/generate-pipeline.sh"
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
  rules:
    - if: '\$TARGET_BRANCH == \$CI_DEFAULT_BRANCH'
      when: manual
      changes: *changes-${state}
EOF
done
