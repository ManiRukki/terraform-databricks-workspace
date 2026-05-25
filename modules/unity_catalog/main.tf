# modules/unity_catalog/main.tf
# Provisions Unity Catalog metastore, catalog, schemas, and grants

terraform {
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.workspace, databricks.account]
    }
  }
}

# ── STORAGE CREDENTIAL ────────────────────────────────────────────────────────
resource "databricks_storage_credential" "unity_catalog" {
  provider = databricks.workspace
  name     = "uc-storage-credential-${var.environment}"

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.unity_catalog.id
  }

  comment = "Storage credential for Unity Catalog metastore root storage"
}

# ── ACCESS CONNECTOR (Managed Identity for UC) ────────────────────────────────
resource "azurerm_databricks_access_connector" "unity_catalog" {
  name                = "dbac-uc-${var.environment}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

# RBAC: grant the access connector managed identity access to ADLS
resource "azurerm_role_assignment" "uc_storage_contributor" {
  scope                = var.adls_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity_catalog.identity[0].principal_id
}

data "azurerm_resource_group" "main" {
  name = split("/", var.adls_account_id)[4]
}

# ── EXTERNAL LOCATION (root storage for metastore) ────────────────────────────
resource "databricks_external_location" "metastore_root" {
  provider        = databricks.workspace
  name            = "metastore-root-${var.environment}"
  url             = "abfss://${var.unity_catalog_container}@${var.storage_account_name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.unity_catalog.id
  comment         = "Root storage for Unity Catalog metastore"
}

# ── METASTORE ─────────────────────────────────────────────────────────────────
resource "databricks_metastore" "main" {
  provider      = databricks.account
  name          = var.metastore_name
  storage_root  = databricks_external_location.metastore_root.url
  region        = "eastus2"
  force_destroy = var.environment != "prod"
}

# Assign workspace to metastore
resource "databricks_metastore_assignment" "main" {
  provider             = databricks.account
  metastore_id         = databricks_metastore.main.id
  workspace_id         = var.workspace_id
  default_catalog_name = "${var.environment}_catalog"
}

# ── CATALOG ───────────────────────────────────────────────────────────────────
resource "databricks_catalog" "main" {
  provider     = databricks.workspace
  metastore_id = databricks_metastore.main.id
  name         = "${var.environment}_catalog"
  comment      = "Main catalog for ${var.environment} environment"
  force_destroy = var.environment != "prod"

  depends_on = [databricks_metastore_assignment.main]
}

# ── SCHEMAS (Bronze / Silver / Gold / Sandbox) ────────────────────────────────
resource "databricks_schema" "bronze" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.main.id
  name         = "bronze"
  comment      = "Raw ingested data — append-only, no transformations"
}

resource "databricks_schema" "silver" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.main.id
  name         = "silver"
  comment      = "Validated, deduplicated, enriched data"
}

resource "databricks_schema" "gold" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.main.id
  name         = "gold"
  comment      = "Business-ready aggregations and mart models"
}

resource "databricks_schema" "sandbox" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.main.id
  name         = "sandbox"
  comment      = "Scratch space for experimentation — not production"
}

# ── GRANTS ────────────────────────────────────────────────────────────────────
# Data engineers: full access to all schemas
resource "databricks_grants" "catalog_data_engineers" {
  provider = databricks.workspace
  catalog  = databricks_catalog.main.id

  grant {
    principal  = "data-engineers"
    privileges = ["USE_CATALOG", "CREATE_SCHEMA", "CREATE_TABLE", "USE_SCHEMA"]
  }
}

# Analysts: read-only on Gold
resource "databricks_grants" "gold_analysts" {
  provider = databricks.workspace
  schema   = "${databricks_catalog.main.id}.gold"

  grant {
    principal  = "data-analysts"
    privileges = ["USE_SCHEMA", "SELECT"]
  }
}

# Data scientists: read on Silver + Gold
resource "databricks_grants" "silver_data_science" {
  provider = databricks.workspace
  schema   = "${databricks_catalog.main.id}.silver"

  grant {
    principal  = "data-scientists"
    privileges = ["USE_SCHEMA", "SELECT"]
  }
}
