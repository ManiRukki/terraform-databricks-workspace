# Terraform Databricks Workspace — Azure

Production-grade Infrastructure-as-Code for provisioning a fully configured Azure Databricks workspace with Unity Catalog governance, job clusters, networking, and IAM — deployed across dev, staging, and production environments via GitHub Actions CI/CD.

---

## Architecture

```
Azure Subscription
└── Resource Group (per environment)
    ├── Azure Databricks Workspace
    │   ├── Unity Catalog (metastore + catalog + schema)
    │   ├── Job Clusters (data engineering workloads)
    │   ├── All-Purpose Cluster (interactive dev)
    │   ├── Cluster Policies (cost governance)
    │   └── Secret Scopes (Key Vault integration)
    ├── Azure Data Lake Storage Gen2 (ADLS)
    │   ├── Bronze container
    │   ├── Silver container
    │   └── Gold container
    ├── Azure Key Vault (secrets management)
    └── Virtual Network (private networking)
        ├── Databricks public subnet
        └── Databricks private subnet
```

---

## Repository Structure

```
terraform-databricks-workspace/
├── modules/
│   ├── databricks_workspace/     # Core workspace provisioning
│   ├── unity_catalog/            # UC metastore, catalog, schema, grants
│   ├── clusters/                 # Job + all-purpose cluster configs
│   └── networking/               # VNet, subnets, NSGs
├── environments/
│   ├── dev/                      # Dev environment tfvars + backend
│   ├── staging/                  # Staging environment
│   └── prod/                     # Production environment
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml    # PR: plan on every pull request
│       └── terraform-apply.yml   # Main: apply on merge to main
├── main.tf                       # Root module composition
├── variables.tf                  # Input variable declarations
├── outputs.tf                    # Output values
├── versions.tf                   # Provider + Terraform version locks
├── backend.tf                    # Remote state (Azure Storage)
└── README.md
```

---

## What Gets Provisioned

| Resource | Details |
|---|---|
| Databricks Workspace | Premium tier, VNet-injected |
| Unity Catalog Metastore | With ADLS Gen2 root storage |
| Catalogs | `{env}_catalog` per environment |
| Schemas | `bronze`, `silver`, `gold`, `sandbox` |
| Job Cluster | Autoscaling, spot instances, DBR 14.3 LTS |
| All-Purpose Cluster | Dev only, auto-terminate 30 min |
| Cluster Policy | DBU limits, node type restrictions |
| Secret Scope | Azure Key Vault-backed |
| Storage Account | ADLS Gen2, hierarchical namespace |
| Key Vault | For Databricks secrets |
| VNet | With Databricks subnets + NSGs |
| IAM | Managed Identity, RBAC assignments |

---

## Quick Start

### Prerequisites
- Terraform >= 1.6.0
- Azure CLI authenticated (`az login`)
- Azure subscription with Contributor access
- Databricks account admin access

### Deploy Dev Environment

```bash
# Clone the repo
git clone https://github.com/ManiRukki/terraform-databricks-workspace.git
cd terraform-databricks-workspace

# Initialize with dev backend
cd environments/dev
terraform init -backend-config=backend.hcl

# Plan
terraform plan -var-file=terraform.tfvars -out=tfplan

# Apply
terraform apply tfplan
```

### Destroy

```bash
terraform destroy -var-file=terraform.tfvars
```

---

## Environment Configuration

Each environment has its own `terraform.tfvars`:

```hcl
# environments/dev/terraform.tfvars
environment         = "dev"
location            = "eastus2"
resource_group_name = "rg-databricks-dev"
workspace_name      = "dbw-mani-dev"
node_type_id        = "Standard_DS3_v2"
min_workers         = 1
max_workers         = 4
auto_terminate_min  = 30
enable_unity_catalog = true
tags = {
  Environment = "dev"
  Owner       = "mani-koliparthi"
  Project     = "lakehouse-platform"
}
```

---

## CI/CD Pipeline

```
Pull Request → terraform fmt → terraform validate → terraform plan (comment on PR)
Merge to main → terraform apply (dev auto, staging/prod manual approval)
```

GitHub Actions workflows handle:
- Automatic `terraform plan` on every PR with results posted as PR comment
- `terraform apply` on merge to `main` (dev auto-applies, staging/prod require manual approval)
- State locking via Azure Storage backend
- Secret injection via GitHub Secrets

---

## Tech Stack

`Terraform` `Azure Databricks` `Unity Catalog` `Azure ADLS Gen2`
`Azure Key Vault` `Azure VNet` `GitHub Actions` `Azure Storage (remote state)`

---

## Related Projects

- [streaming-event-pipeline](https://github.com/ManiRukki/streaming_event_pipeline) — Kafka + Flink + DLT running on this workspace
- [customer-analytics-platform](https://github.com/ManiRukki/customer-analytics-platform) — CVS Health dbt platform on this infra
