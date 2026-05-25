# modules/databricks_workspace/main.tf
# Provisions the Azure Databricks workspace + Key Vault secret scope

resource "azurerm_databricks_workspace" "main" {
  name                = var.workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  tags                = var.tags

  # VNet injection (private networking)
  dynamic "custom_parameters" {
    for_each = var.enable_vnet_injection ? [1] : []
    content {
      no_public_ip                                         = true
      virtual_network_id                                   = var.virtual_network_id
      public_subnet_name                                   = var.public_subnet_name
      private_subnet_name                                  = var.private_subnet_name
      public_subnet_network_security_group_association_id  = var.public_subnet_nsg_id
      private_subnet_network_security_group_association_id = var.private_subnet_nsg_id
    }
  }

  lifecycle {
    # Prevent accidental destruction of the workspace
    prevent_destroy = false # set to true in prod
  }
}

# ── SECRET SCOPE (Key Vault-backed) ──────────────────────────────────────────
resource "databricks_secret_scope" "keyvault" {
  name = "keyvault-secrets"

  keyvault_metadata {
    resource_id = var.key_vault_id
    dns_name    = var.key_vault_uri
  }

  depends_on = [azurerm_databricks_workspace.main]
}

# ── STORE ADLS KEY IN KEY VAULT ───────────────────────────────────────────────
resource "azurerm_key_vault_secret" "adls_key" {
  name         = "adls-storage-account-key"
  value        = var.storage_account_key
  key_vault_id = var.key_vault_id

  lifecycle {
    ignore_changes = [value] # prevent rotation on every apply
  }
}

# ── MANAGED IDENTITY → STORAGE RBAC ──────────────────────────────────────────
resource "azurerm_role_assignment" "workspace_storage_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.storage_account_name}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_workspace.main.storage_account_identity[0].principal_id
}

data "azurerm_client_config" "current" {}
