output "project_urls" {
  description = "Web URL of each created app repo."
  value       = { for k, p in gitlab_project.app : k => p.web_url }
}

output "project_ids" {
  description = "Numeric project ID of each created app repo."
  value       = { for k, p in gitlab_project.app : k => p.id }
}
