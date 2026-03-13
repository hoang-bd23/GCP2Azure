output "key_ring_id" {
  description = "KMS key ring ID"
  value       = google_kms_key_ring.this.id
}

output "key_ids" {
  description = "Map of KMS key IDs"
  value       = { for k, v in google_kms_crypto_key.keys : k => v.id }
}
