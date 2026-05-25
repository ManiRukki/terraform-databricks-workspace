## modules/databricks_workspace/variables.tf

variable "workspace_name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "sku" { type = string; default = "premium" }
variable "tags" { type = map(string); default = {} }
variable "enable_vnet_injection" { type = bool; default = true }
variable "virtual_network_id" { type = string; default = null }
variable "public_subnet_name" { type = string; default = null }
variable "private_subnet_name" { type = string; default = null }
variable "public_subnet_nsg_id" { type = string; default = null }
variable "private_subnet_nsg_id" { type = string; default = null }
variable "key_vault_id" { type = string }
variable "key_vault_uri" { type = string }
variable "storage_account_name" { type = string }
variable "storage_account_key" { type = string; sensitive = true }
