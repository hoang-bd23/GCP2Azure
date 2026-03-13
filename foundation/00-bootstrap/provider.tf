terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.30.0"
    }
  }
}

# Bootstrap uses org-level credentials (your user account)
# No default project — the seed project is created by this layer
provider "google" {
  region = var.region
}
