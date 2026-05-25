# ── ENVIRONMENT ──────────────────────────────────────────────────────────────
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ── DATABRICKS ───────────────────────────────────────────────────────────────
variable "workspace_name" {
  description = "Name of the Databricks workspace"
  type        = string
}

variable "databricks_sku" {
  description = "Databricks workspace SKU (standard, premium, trial)"
  type        = string
  default     = "premium"
  validation {
    condition     = contains(["standard", "premium", "trial"], var.databricks_sku)
    error_message = "SKU must be standard, premium, or trial."
  }
}

variable "databricks_account_id" {
  description = "Databricks account ID (for Unity Catalog account-level operations)"
  type        = string
  sensitive   = true
}

# ── UNITY CATALOG ─────────────────────────────────────────────────────────────
variable "enable_unity_catalog" {
  description = "Whether to enable Unity Catalog for this workspace"
  type        = bool
  default     = true
}

variable "metastore_name" {
  description = "Name of the Unity Catalog metastore"
  type        = string
  default     = "primary-metastore"
}

# ── CLUSTERS ─────────────────────────────────────────────────────────────────
variable "node_type_id" {
  description = "Azure VM type for Databricks cluster nodes"
  type        = string
  default     = "Standard_DS3_v2"
}

variable "spark_version" {
  description = "Databricks Runtime version"
  type        = string
  default     = "14.3.x-scala2.12"
}

variable "min_workers" {
  description = "Minimum number of workers for autoscaling job cluster"
  type        = number
  default     = 1
  validation {
    condition     = var.min_workers >= 1
    error_message = "Minimum workers must be at least 1."
  }
}

variable "max_workers" {
  description = "Maximum number of workers for autoscaling job cluster"
  type        = number
  default     = 8
  validation {
    condition     = var.max_workers <= 20
    error_message = "Maximum workers cannot exceed 20 (cost governance)."
  }
}

variable "auto_terminate_min" {
  description = "Auto-termination timeout in minutes for all-purpose cluster"
  type        = number
  default     = 30
}

variable "max_dbu_per_hour" {
  description = "Maximum DBUs per hour enforced by cluster policy"
  type        = number
  default     = 10
}

# ── NETWORKING ───────────────────────────────────────────────────────────────
variable "enable_vnet_injection" {
  description = "Whether to deploy Databricks in a custom VNet (recommended for prod)"
  type        = bool
  default     = true
}

variable "vnet_address_space" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for Databricks public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for Databricks private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# ── STORAGE ───────────────────────────────────────────────────────────────────
variable "storage_account_tier" {
  description = "Storage account performance tier"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage replication strategy (LRS, ZRS, GRS)"
  type        = string
  default     = "ZRS"
  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS"], var.storage_replication_type)
    error_message = "Replication type must be LRS, ZRS, GRS, or RAGRS."
  }
}
