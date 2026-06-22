variable "gitlab_token" {
  type        = string
  description = "GitLab token (api scope) used to create projects and set group variables."
  sensitive   = true
}

variable "gitlab_base_url" {
  type        = string
  description = "GitLab API base URL. Empty = gitlab.com (e.g. https://gitlab.example.com/api/v4/)."
  default     = ""
}

variable "parent_namespace_id" {
  type        = number
  description = "Numeric ID of the group under which each app repo is created. Also receives the shared service-principal CI/CD variables."
}

# --- Custom project template (one-time GitLab prerequisite) ------------------
# The template project must already be registered under a group designated for
# custom project templates (Group > Settings > General > Custom project
# templates). The provider does not manage that group setting.
variable "template_name" {
  type        = string
  description = "Path (name) of the custom project template project to seed each repo from."
}

variable "template_group_id" {
  type        = number
  description = "Numeric ID of the group registered to hold custom project templates."
}

# --- Shared service principal (set once at the group level) ------------------
variable "arm_tenant_id" {
  type        = string
  description = "Entra tenant ID of the single shared service principal."
}

variable "arm_client_id" {
  type        = string
  description = "App ID of the single shared service principal (rights on every spoke sub + the hub)."
}

variable "arm_client_secret" {
  type        = string
  description = "Secret of the shared service principal."
  sensitive   = true
}

# --- Environment model -------------------------------------------------------
variable "environments" {
  type        = list(string)
  description = "Environments provisioned in every app repo."
  default     = ["dev", "sim", "uat", "exp"]
}

variable "approval_envs" {
  type        = list(string)
  description = "Environments gated by a protected-environment approval before apply."
  default     = ["uat", "exp"]
}

variable "approver_group_id" {
  type        = number
  description = "Group whose members may approve gated deployments."
}
