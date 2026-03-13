resource "google_compute_firewall" "rules" {
  for_each = { for rule in var.rules : rule.name => rule }

  name      = each.value.name
  project   = var.project_id
  network   = var.network
  direction = each.value.direction
  priority  = each.value.priority

  description = each.value.description

  source_ranges      = each.value.direction == "INGRESS" ? each.value.ranges : null
  destination_ranges = each.value.direction == "EGRESS" ? each.value.ranges : null

  source_tags = length(each.value.source_tags) > 0 ? each.value.source_tags : null
  target_tags = length(each.value.target_tags) > 0 ? each.value.target_tags : null

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }
}
