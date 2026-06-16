variable "name" {
  type        = string
  description = "Name of the spoke VNet."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the spoke VNet."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "address_space" {
  type        = list(string)
  description = "Address space(s) for the VNet."
}

variable "subnets" {
  type = list(object({
    name   = string
    prefix = string
  }))
  description = "Subnets to create in the VNet."
}

variable "dns_servers" {
  type        = list(string)
  default     = []
  description = "Custom DNS servers for the VNet (empty = Azure-provided DNS)."
}

variable "hub_vnet_id" {
  type        = string
  description = "Resource ID of the hub VNet to peer with."
}

variable "spoke_label" {
  type        = string
  description = "Label used to name the hub->spoke peering."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to created resources."
}
