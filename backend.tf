# Remote state stored in Azure Storage Account
# Each environment uses a different state file key

terraform {
  backend "azurerm" {
    # These values are injected at init time via -backend-config=backend.hcl
    # or via environment variables (ARM_ACCESS_KEY etc.)
    # DO NOT hardcode storage account names or keys here
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatemaniplatform"
    container_name       = "tfstate"
    key                  = "databricks.tfstate" # overridden per environment
  }
}

# ── HOW TO USE ────────────────────────────────────────────────────────────────
# Dev:
#   terraform init -backend-config=environments/dev/backend.hcl
#
# Staging:
#   terraform init -backend-config=environments/staging/backend.hcl
#
# Prod:
#   terraform init -backend-config=environments/prod/backend.hcl
#
# Backend authentication — set these environment variables:
#   ARM_ACCESS_KEY      → storage account access key (preferred for CI)
#   or ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID → service principal
