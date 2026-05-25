# ── DATA SOURCES ─────────────────────────────────────────────────────────────
data "azurerm_client_config" "current" {}

# ── RESOURCE GROUP ────────────────────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ── LOCALS ────────────────────────────────────────────────────────────────────
locals {
  common_tags = merge(var.tags, {
    ManagedBy   = "terraform"
    Environment = var.environment
    UpdatedAt   = timestamp()
  })

  # Naming convention: {resource_abbr}-{project}-{env}-{random_suffix}
  name_prefix = "mani-lakehouse-${var.environment}"
}

# ── RANDOM SUFFIX (avoids name collisions) ────────────────────────────────────
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# ── NETWORKING MODULE ─────────────────────────────────────────────────────────
module "networking" {
  count  = var.enable_vnet_injection ? 1 : 0
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  name_prefix         = local.name_prefix
  vnet_address_space  = var.vnet_address_space
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  tags                = local.common_tags
}

# ── STORAGE (ADLS Gen2) ───────────────────────────────────────────────────────
resource "azurerm_storage_account" "adls" {
  name                     = "adls${replace(local.name_prefix, "-", "")}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  account_kind             = "StorageV2"
  is_hns_enabled           = true # hierarchical namespace = ADLS Gen2

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = local.common_tags
}

# Bronze / Silver / Gold containers
resource "azurerm_storage_container" "bronze" {
  name                  = "bronze"
  storage_account_name  = azurerm_storage_account.adls.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "silver" {
  name                  = "silver"
  storage_account_name  = azurerm_storage_account.adls.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "gold" {
  name                  = "gold"
  storage_account_name  = azurerm_storage_account.adls.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "unity_catalog" {
  name                  = "unity-catalog"
  storage_account_name  = azurerm_storage_account.adls.name
  container_access_type = "private"
}

# ── KEY VAULT ─────────────────────────────────────────────────────────────────
resource "azurerm_key_vault" "main" {
  name                       = "kv-${local.name_prefix}-${random_string.suffix.result}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.environment == "prod" ? true : false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
  }

  tags = local.common_tags
}

# ── DATABRICKS WORKSPACE MODULE ───────────────────────────────────────────────
module "databricks_workspace" {
  source = "./modules/databricks_workspace"

  workspace_name      = var.workspace_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = var.databricks_sku
  tags                = local.common_tags

  # VNet injection (if enabled)
  enable_vnet_injection    = var.enable_vnet_injection
  virtual_network_id       = var.enable_vnet_injection ? module.networking[0].vnet_id : null
  public_subnet_name       = var.enable_vnet_injection ? module.networking[0].public_subnet_name : null
  private_subnet_name      = var.enable_vnet_injection ? module.networking[0].private_subnet_name : null
  public_subnet_nsg_id     = var.enable_vnet_injection ? module.networking[0].public_nsg_id : null
  private_subnet_nsg_id    = var.enable_vnet_injection ? module.networking[0].private_nsg_id : null

  # Key Vault integration
  key_vault_id  = azurerm_key_vault.main.id
  key_vault_uri = azurerm_key_vault.main.vault_uri

  # Storage
  storage_account_name = azurerm_storage_account.adls.name
  storage_account_key  = azurerm_storage_account.adls.primary_access_key
}

# ── UNITY CATALOG MODULE ──────────────────────────────────────────────────────
module "unity_catalog" {
  count  = var.enable_unity_catalog ? 1 : 0
  source = "./modules/unity_catalog"

  providers = {
    databricks.workspace = databricks.workspace
    databricks.account   = databricks.account
  }

  environment           = var.environment
  metastore_name        = var.metastore_name
  workspace_id          = module.databricks_workspace.workspace_id
  storage_account_name  = azurerm_storage_account.adls.name
  unity_catalog_container = azurerm_storage_container.unity_catalog.name
  adls_account_id       = azurerm_storage_account.adls.id
  tenant_id             = data.azurerm_client_config.current.tenant_id

  depends_on = [module.databricks_workspace]
}

# ── CLUSTERS MODULE ───────────────────────────────────────────────────────────
module "clusters" {
  source = "./modules/clusters"

  providers = {
    databricks = databricks.workspace
  }

  environment        = var.environment
  spark_version      = var.spark_version
  node_type_id       = var.node_type_id
  min_workers        = var.min_workers
  max_workers        = var.max_workers
  auto_terminate_min = var.auto_terminate_min
  max_dbu_per_hour   = var.max_dbu_per_hour

  # Pass storage config as Spark conf
  storage_account_name = azurerm_storage_account.adls.name
  storage_account_key  = azurerm_storage_account.adls.primary_access_key

  depends_on = [module.databricks_workspace]
}
