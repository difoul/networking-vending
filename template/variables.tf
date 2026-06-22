# Selects which env config to load: config/<env>.json. The app dimension is
# gone - this repo IS one app; only the environment varies (set per CI job).
variable "env" {
  type        = string
  description = "Environment name; matches the JSON file under config/."

  validation {
    condition     = contains(["dev", "sim", "uat", "exp"], var.env)
    error_message = "env must be one of: dev, sim, uat, exp."
  }
}
