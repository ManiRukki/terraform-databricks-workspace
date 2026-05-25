# environments/prod/terraform.tfvars

environment         = "prod"
location            = "eastus2"
resource_group_name = "rg-databricks-prod"
workspace_name      = "dbw-mani-prod"
databricks_sku      = "premium"

# Cluster config — larger for prod workloads
node_type_id        = "Standard_DS4_v2"
spark_version       = "14.3.x-scala2.12"
min_workers         = 2
max_workers         = 16
auto_terminate_min  = 60
max_dbu_per_hour    = 20

# Unity Catalog
enable_unity_catalog = true
metastore_name       = "mani-metastore-prod"

# Networking
enable_vnet_injection = true
vnet_address_space    = "10.2.0.0/16"
public_subnet_cidr    = "10.2.1.0/24"
private_subnet_cidr   = "10.2.2.0/24"

# Storage — ZRS for production resilience
storage_account_tier     = "Standard"
storage_replication_type = "ZRS"

tags = {
  Environment = "prod"
  Owner       = "mani-koliparthi"
  Project     = "lakehouse-platform"
  CostCenter  = "data-engineering"
  Criticality = "high"
}
