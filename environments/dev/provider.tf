terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.30.0"
    }
  }

  backend "gcs" {
    prefix = "05-env-dev"
  }
}

provider "google" {
  project               = var.dev_project_id
  region                = var.region
  user_project_override = true
  billing_project       = var.dev_project_id
}
