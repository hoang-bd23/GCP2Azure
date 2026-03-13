output "key_ring_id" {
  description = "KMS key ring ID"
  value       = module.security.key_ring_id
}

output "key_ids" {
  description = "KMS key IDs"
  value       = module.security.key_ids
}
