variable "project_id" {
  description = "Project ID for the firewall rules"
  type        = string
}

variable "network" {
  description = "VPC network self link or name"
  type        = string
}

variable "rules" {
  description = "List of firewall rules"
  type = list(object({
    name        = string
    description = optional(string, "")
    direction   = optional(string, "INGRESS")
    priority    = optional(number, 1000)
    ranges      = list(string)
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    target_tags = optional(list(string), [])
    source_tags = optional(list(string), [])
  }))
  default = []
}
