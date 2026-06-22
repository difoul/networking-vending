# Single shared service principal, set once at the GROUP level. Every app repo
# created under parent_namespace_id inherits these CI/CD variables, so the
# factory never provisions per-repo or env-scoped credentials.
resource "gitlab_group_variable" "arm_tenant_id" {
  group     = var.parent_namespace_id
  key       = "ARM_TENANT_ID"
  value     = var.arm_tenant_id
  protected = true
  masked    = true
}

resource "gitlab_group_variable" "arm_client_id" {
  group     = var.parent_namespace_id
  key       = "ARM_CLIENT_ID"
  value     = var.arm_client_id
  protected = true
  masked    = true
}

resource "gitlab_group_variable" "arm_client_secret" {
  group     = var.parent_namespace_id
  key       = "ARM_CLIENT_SECRET"
  value     = var.arm_client_secret
  protected = true
  masked    = true
}
