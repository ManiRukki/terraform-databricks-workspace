terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.35"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Databricks provider — workspace-level (used after workspace creation)
provider "databricks" {
  alias = "workspace"
  host  = module.databricks_workspace.workspace_url
  # Authentication via Azure managed identity or Azure CLI
  azure_workspace_resource_id = module.databricks_workspace.workspace_id
}

# Databricks provider — account-level (used for Unity Catalog metastore)
provider "databricks" {
  alias      = "account"
  host       = "https://accounts.azuredatabricks.net"
  account_id = var.databricks_account_id
}
