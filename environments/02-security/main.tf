module "security" {
  source = "../../modules/security"

  project_id        = var.project_id
  org_id            = var.org_id
  region            = var.region
  kms_key_ring_name = var.kms_key_ring_name
  kms_keys          = var.kms_keys

  org_iam_bindings = [
    {
      role   = "roles/securitycenter.admin"
      member = "serviceAccount:${var.terraform_sa_email}"
    },
    {
      role   = "roles/logging.admin"
      member = "serviceAccount:${var.terraform_sa_email}"
    },
    {
      role   = "roles/iam.organizationRoleAdmin"
      member = "serviceAccount:${var.terraform_sa_email}"
    },
  ]
}
