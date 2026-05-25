# ── WORKSPACE ────────────────────────────────────────────────────────────────
output "workspace_url" {
  description = "URL of the Databricks workspace"
  value       = module.databricks_workspace.workspace_url
}

output "workspace_id" {
  description = "Azure resource ID of the Databricks workspace"
  value       = module.databricks_workspace.workspace_id
}

output "workspace_name" {
  description = "Name of the Databricks workspace"
  value       = var.workspace_name
}

# ── STORAGE ───────────────────────────────────────────────────────────────────
output "storage_account_name" {
  description = "ADLS Gen2 storage account name"
  value       = azurerm_storage_account.adls.name
}

output "storage_account_dfs_endpoint" {
  description = "Primary DFS endpoint for ADLS Gen2"
  value       = azurerm_storage_account.adls.primary_dfs_endpoint
}

output "bronze_container_path" {
  description = "ABFS path to the Bronze container"
  value       = "abfss://bronze@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
}

output "silver_container_path" {
  description = "ABFS path to the Silver container"
  value       = "abfss://silver@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
}

output "gold_container_path" {
  description = "ABFS path to the Gold container"
  value       = "abfss://gold@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
}

# ── KEY VAULT ─────────────────────────────────────────────────────────────────
output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

# ── CLUSTERS ─────────────────────────────────────────────────────────────────
output "job_cluster_policy_id" {
  description = "ID of the job cluster policy"
  value       = module.clusters.job_cluster_policy_id
}

output "all_purpose_cluster_id" {
  description = "ID of the all-purpose cluster (dev only)"
  value       = module.clusters.all_purpose_cluster_id
}

# ── UNITY CATALOG ─────────────────────────────────────────────────────────────
output "metastore_id" {
  description = "ID of the Unity Catalog metastore"
  value       = var.enable_unity_catalog ? module.unity_catalog[0].metastore_id : null
}

output "catalog_name" {
  description = "Name of the environment catalog"
  value       = var.enable_unity_catalog ? module.unity_catalog[0].catalog_name : null
}

# ── NETWORKING ────────────────────────────────────────────────────────────────
output "vnet_id" {
  description = "ID of the virtual network (if VNet injection enabled)"
  value       = var.enable_vnet_injection ? module.networking[0].vnet_id : null
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}
