terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }

  backend "gcs" {
    prefix = "azure-hybrid-vpn"
  }
}

provider "azurerm" {
  features {}
  
  resource_provider_registrations = "none"

  subscription_id = var.azure_subscription_id
}
