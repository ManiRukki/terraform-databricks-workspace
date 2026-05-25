# modules/clusters/main.tf
# Provisions cluster policy, job cluster config, and all-purpose cluster (dev only)

terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
  }
}

# ── CLUSTER POLICY (cost governance) ─────────────────────────────────────────
resource "databricks_cluster_policy" "data_engineering" {
  name = "data-engineering-policy-${var.environment}"

  definition = jsonencode({
    # Force specific Spark version
    "spark_version" = {
      "type"  = "fixed"
      "value" = var.spark_version
    }
    # Restrict node types to approved VM sizes
    "node_type_id" = {
      "type"         = "allowlist"
      "values"       = ["Standard_DS3_v2", "Standard_DS4_v2", "Standard_DS5_v2"]
      "defaultValue" = var.node_type_id
    }
    # Enforce auto-termination
    "autotermination_minutes" = {
      "type"  = "fixed"
      "value" = tostring(var.auto_terminate_min)
    }
    # Cap max workers (cost control)
    "autoscale.max_workers" = {
      "type"     = "range"
      "maxValue" = var.max_workers
    }
    # Force spot instances where possible
    "azure_attributes.availability" = {
      "type"  = "fixed"
      "value" = var.environment == "prod" ? "ON_DEMAND_AZURE" : "SPOT_WITH_FALLBACK_AZURE"
    }
    # Required tags for cost attribution
    "custom_tags.Environment" = {
      "type"  = "fixed"
      "value" = var.environment
    }
    "custom_tags.ManagedBy" = {
      "type"  = "fixed"
      "value" = "terraform"
    }
  })
}

# ── JOB CLUSTER CONFIGURATION ─────────────────────────────────────────────────
# This is a reusable cluster config for Databricks Jobs (not a running cluster)
# Reference this in your job definitions as new_cluster
resource "databricks_cluster" "job_cluster_template" {
  cluster_name            = "job-cluster-${var.environment}"
  spark_version           = var.spark_version
  node_type_id            = var.node_type_id
  autotermination_minutes = var.auto_terminate_min
  policy_id               = databricks_cluster_policy.data_engineering.id
  data_security_mode      = "SINGLE_USER"

  autoscale {
    min_workers = var.min_workers
    max_workers = var.max_workers
  }

  azure_attributes {
    availability       = var.environment == "prod" ? "ON_DEMAND_AZURE" : "SPOT_WITH_FALLBACK_AZURE"
    first_on_demand    = 1
    spot_bid_max_price = 100
  }

  spark_conf = {
    # ADLS Gen2 access via storage account key (prefer managed identity in prod)
    "fs.azure.account.key.${var.storage_account_name}.dfs.core.windows.net" = var.storage_account_key

    # Delta Lake optimizations
    "spark.databricks.delta.optimizeWrite.enabled"  = "true"
    "spark.databricks.delta.autoCompact.enabled"    = "true"
    "spark.sql.extensions"                          = "io.delta.sql.DeltaSparkSessionExtension"
    "spark.sql.catalog.spark_catalog"              = "org.apache.spark.sql.delta.catalog.DeltaCatalog"

    # Adaptive query execution
    "spark.sql.adaptive.enabled"              = "true"
    "spark.sql.adaptive.coalescePartitions.enabled" = "true"

    # Timezone
    "spark.sql.session.timeZone" = "UTC"
  }

  spark_env_vars = {
    ENVIRONMENT = var.environment
  }

  custom_tags = {
    Environment = var.environment
    ClusterType = "job"
    ManagedBy   = "terraform"
  }

  library {
    pypi {
      package = "dbt-databricks==1.7.3"
    }
  }

  library {
    pypi {
      package = "great-expectations==0.18.8"
    }
  }

  library {
    pypi {
      package = "mlflow==2.10.0"
    }
  }
}

# ── ALL-PURPOSE CLUSTER (dev/staging only) ────────────────────────────────────
resource "databricks_cluster" "all_purpose" {
  count = var.environment != "prod" ? 1 : 0

  cluster_name            = "all-purpose-${var.environment}"
  spark_version           = var.spark_version
  node_type_id            = var.node_type_id
  autotermination_minutes = var.auto_terminate_min
  policy_id               = databricks_cluster_policy.data_engineering.id
  data_security_mode      = "SINGLE_USER"
  single_user_name        = null # set to specific user email if needed

  autoscale {
    min_workers = 1
    max_workers = 4   # capped lower for cost in non-prod
  }

  azure_attributes {
    availability = "SPOT_WITH_FALLBACK_AZURE"
  }

  spark_conf = {
    "fs.azure.account.key.${var.storage_account_name}.dfs.core.windows.net" = var.storage_account_key
    "spark.databricks.delta.optimizeWrite.enabled"  = "true"
    "spark.sql.adaptive.enabled"              = "true"
    "spark.sql.session.timeZone"              = "UTC"
  }

  custom_tags = {
    Environment = var.environment
    ClusterType = "all-purpose"
    ManagedBy   = "terraform"
  }
}
