output "firewall_rules" {
  description = "Map of created firewall rules"
  value = {
    for name, rule in google_compute_firewall.rules : name => {
      id        = rule.id
      name      = rule.name
      self_link = rule.self_link
    }
  }
}
