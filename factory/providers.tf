terraform {
  required_version = ">= 1.9"

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 19.0"
    }
  }

  # The factory keeps its own single GitLab-managed state (one state, not
  # per-app). Backend settings are supplied at `terraform init` in CI.
  backend "http" {}
}

provider "gitlab" {
  token = var.gitlab_token
  # Empty -> gitlab.com. Set to your self-managed API base, e.g.
  # https://gitlab.example.com/api/v4/
  base_url = var.gitlab_base_url
}
