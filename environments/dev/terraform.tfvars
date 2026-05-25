# environments/dev/terraform.tfvars

environment         = "dev"
location            = "eastus2"
resource_group_name = "rg-databricks-dev"
workspace_name      = "dbw-mani-dev"
databricks_sku      = "premium"

# Cluster config — small for dev
node_type_id        = "Standard_DS3_v2"
spark_version       = "14.3.x-scala2.12"
min_workers         = 1
max_workers         = 4
auto_terminate_min  = 30
max_dbu_per_hour    = 5

# Unity Catalog
enable_unity_catalog = true
metastore_name       = "mani-metastore-dev"

# Networking — VNet injection for all environments
enable_vnet_injection = true
vnet_address_space    = "10.0.0.0/16"
public_subnet_cidr    = "10.0.1.0/24"
private_subnet_cidr   = "10.0.2.0/24"

# Storage
storage_account_tier     = "Standard"
storage_replication_type = "LRS"  # LRS is fine for dev

tags = {
  Environment = "dev"
  Owner       = "mani-koliparthi"
  Project     = "lakehouse-platform"
  CostCenter  = "data-engineering"
}
