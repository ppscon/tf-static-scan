# GitHub Actions Workflows

## Available Workflows

### 1. Terraform Security Scan (`terraform-security-scan.yml`)

**Purpose:** Basic security scanning of Terraform plans against REGO policies.

**Triggers:**
- Pull requests to `master` or `main`
- Push to `master` or `main`
- Manual workflow dispatch

**What it does:**
1. Sets up Terraform and OPA
2. Generates Terraform plan from examples
3. Runs security scan with REGO policies
4. Checks for HIGH severity violations and fails if found
5. Uploads scan results as artifacts

**Usage:**
```bash
# Triggered automatically on PR/push, or run manually:
gh workflow run terraform-security-scan.yml
```

---

### 2. Azure Integration Test (`azure-integration-test.yml`)

**Purpose:** Advanced testing with Azure cloud resources and optional AKS deployment.

**Triggers:**
- Manual workflow dispatch only

**Prerequisites:**
- Azure credentials stored in GitHub secrets:
  - `AQUA_KEY` (Service Principal App ID)
  - `AQUA_PASSWORD` (Service Principal Password)
  - `AQUA_SECRET` (Tenant ID)
  - `AQUA_SERVER` (Subscription ID)
- Access to resource group `pp-rg`
- Access to AKS cluster `pp-fips-cbom-demo`

**What it does:**
1. Authenticates with Azure
2. Creates test storage account (optional)
3. Runs Terraform plan and security scan
4. Generates summary report in GitHub Actions UI
5. Optionally deploys scanner to AKS namespace
6. Cleans up test resources

**Usage:**
```bash
# Run with AKS deployment
gh workflow run azure-integration-test.yml -f deploy_to_aks=true

# Run without AKS deployment
gh workflow run azure-integration-test.yml -f deploy_to_aks=false
```

---

## Setup Instructions

### 1. Configure Azure Credentials

See the detailed setup guide: [SETUP-SECRETS.md](../SETUP-SECRETS.md)

**Quick setup:**
```bash
# Create service principal
az ad sp create-for-rbac \
  --name "tf-static-scan-github" \
  --role contributor \
  --scopes /subscriptions/71d0a3d0-ad98-4db0-b732-f95dc566a10a/resourceGroups/pp-rg
```

### 2. Add GitHub Secrets

Map the service principal output to these secrets:

1. `AQUA_KEY` → `appId` from output
2. `AQUA_PASSWORD` → `password` from output
3. `AQUA_SECRET` → `tenant` from output (or `bc034cf3-566b-41ca-9f24-5dc49474b05e`)
4. `AQUA_SERVER` → `71d0a3d0-ad98-4db0-b732-f95dc566a10a`
5. `AQUA_USER` → Same as `AQUA_KEY`

---

## Workflow Results

### Artifacts

Both workflows upload artifacts containing:
- `tfplan.json` - Terraform plan in JSON format
- `scan-results.json` - Security scan results (Azure workflow only)

Artifacts are retained for 30 days.

### Summary Report

The Azure integration test generates a summary table in the Actions UI showing violation counts by severity level.

---

## Local Testing

Test the same commands locally:

```bash
# Install OPA
brew install opa

# Generate plan
cd examples
terraform init -backend=false
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Run scan
opa eval \
  --data ../policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.deny'
```
