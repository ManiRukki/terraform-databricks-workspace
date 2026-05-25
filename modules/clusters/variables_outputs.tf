## modules/clusters/variables.tf

variable "environment" { type = string }
variable "spark_version" { type = string }
variable "node_type_id" { type = string }
variable "min_workers" { type = number }
variable "max_workers" { type = number }
variable "auto_terminate_min" { type = number }
variable "max_dbu_per_hour" { type = number }
variable "storage_account_name" { type = string }
variable "storage_account_key" { type = string; sensitive = true }

---

## modules/clusters/outputs.tf

output "job_cluster_policy_id" {
  value = databricks_cluster_policy.data_engineering.id
}

output "job_cluster_template_id" {
  value = databricks_cluster.job_cluster_template.id
}

output "all_purpose_cluster_id" {
  value = var.environment != "prod" ? databricks_cluster.all_purpose[0].id : null
}

output "spark_version" {
  value = var.spark_version
}
