## modules/databricks_workspace/outputs.tf

output "workspace_url" {
  value = "https://${azurerm_databricks_workspace.main.workspace_url}"
}

output "workspace_id" {
  value = azurerm_databricks_workspace.main.id
}

output "workspace_numeric_id" {
  value = azurerm_databricks_workspace.main.workspace_id
}

output "managed_resource_group_id" {
  value = azurerm_databricks_workspace.main.managed_resource_group_id
}
