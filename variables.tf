# Selects which config file to load: config/<app>/<env>.json
variable "app" {
  type        = string
  description = "Application name; matches the directory under config/."
}

variable "env" {
  type        = string
  description = "Environment name; matches the JSON file name under config/<app>/."

  validation {
    condition     = contains(["dev", "sim", "uat", "exp"], var.env)
    error_message = "env must be one of: dev, sim, uat, exp."
  }
}
