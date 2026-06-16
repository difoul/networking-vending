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
  variables:
    # GitLab-managed state, one state name per subscription. Backend auth is
    # supplied via TF_HTTP_* env vars (resolved fresh in EVERY job) rather than
    # -backend-config flags. Passing the password via -backend-config bakes the
    # plan job's CI_JOB_TOKEN into plan.cache; by the time the separate apply
    # job runs it has expired -> "HTTP remote state endpoint requires auth".
    # Env vars avoid that: each job authenticates with its own live token.
    TF_HTTP_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${STATE_NAME}"
    TF_HTTP_LOCK_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${STATE_NAME}/lock"
    TF_HTTP_UNLOCK_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${STATE_NAME}/lock"
    TF_HTTP_LOCK_METHOD: "POST"
    TF_HTTP_UNLOCK_METHOD: "DELETE"
    TF_HTTP_USERNAME: "gitlab-ci-token"
    TF_HTTP_PASSWORD: "${CI_JOB_TOKEN}"
    TF_HTTP_RETRY_WAIT_MIN: "5"
  before_script:
    # DEMO: no Azure auth needed - we only exercise the GitLab state backend.
    # (The real branch exports ARM_* service-principal credentials here.)
    - terraform init
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
