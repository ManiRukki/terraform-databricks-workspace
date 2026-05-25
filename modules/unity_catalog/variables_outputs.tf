## modules/unity_catalog/variables.tf

variable "environment" { type = string }
variable "metastore_name" { type = string }
variable "workspace_id" { type = string }
variable "storage_account_name" { type = string }
variable "unity_catalog_container" { type = string }
variable "adls_account_id" { type = string }
variable "tenant_id" { type = string }

---

## modules/unity_catalog/outputs.tf

output "metastore_id" {
  value = databricks_metastore.main.id
}

output "catalog_name" {
  value = databricks_catalog.main.name
}

output "bronze_schema" {
  value = "${databricks_catalog.main.name}.bronze"
}

output "silver_schema" {
  value = "${databricks_catalog.main.name}.silver"
}

output "gold_schema" {
  value = "${databricks_catalog.main.name}.gold"
}
