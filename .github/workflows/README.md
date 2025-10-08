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
- Azure credentials stored in GitHub secret `AZURE_CREDENTIALS`
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

Create a service principal and store credentials in GitHub:

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "tf-static-scan-github" \
  --role contributor \
  --scopes /subscriptions/71d0a3d0-ad98-4db0-b732-f95dc566a10a/resourceGroups/pp-rg \
  --sdk-auth

# Copy the JSON output and add it as a GitHub secret named AZURE_CREDENTIALS
```

### 2. Add GitHub Secret

1. Go to your repository Settings
2. Navigate to Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `AZURE_CREDENTIALS`
5. Value: Paste the JSON output from service principal creation

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
