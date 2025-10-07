# Azure Storage REGO Policy Demo Guide

**Problem**: CloudSploit detects Azure storage misconfigurations at runtime (after deployment), but we need to catch them earlier in CI/CD (before deployment).

**Solution**: Custom REGO policies that scan Terraform code and detect CloudSploit-equivalent issues during the planning phase.

---

## 🎯 The Problem Context

### Current State (CloudSploit - Runtime Detection)

```
Developer → Git Push → CI/CD → Terraform Apply → Deploy to Azure → CloudSploit Scan
                                                                         ↓
                                                                   ❌ Finds Issues
                                                                   (Too Late!)
```

**Issues:**
- CloudSploit scans **deployed Azure resources** via Azure API
- Misconfigurations are found **AFTER deployment**
- Requires remediation and redeployment (expensive, time-consuming)
- Security vulnerabilities exist in production during gap

### Example CloudSploit Findings:
```
❌ Storage account 'proddata123' does not have soft delete enabled
❌ Storage account 'logs456' uses LRS (not geo-redundant)
❌ Storage account 'backups789' missing infrastructure encryption
```

### Desired State (Shift-Left with REGO)

```
Developer → Git Push → CI/CD → Terraform Plan → REGO Scan → BLOCK if issues
                                                      ↓
                                              ✅ Catches Issues
                                              (Before Deployment!)
```

**Benefits:**
- Scan **Terraform code** before deployment
- Catch misconfigurations during PR review
- Zero production security gaps
- Faster feedback loop for developers

---

## 🚀 Quick Demo (5 minutes)

### Step 1: Show the Problem - Terraform with Misconfigurations

```bash
cd /Users/home/Developer/CBOM/research

# Show intentionally misconfigured storage account
cat azure-storage-test.tf | grep -A 10 "bad_no_logging"
```

**Output:**
```hcl
# ❌ BAD: Missing blob service logging
resource "azurerm_storage_account" "bad_no_logging" {
  name                     = "storagenologging"
  resource_group_name      = "test-rg"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "LRS"  # ❌ Not geo-redundant

  # Missing: blob_properties with logging
  # Missing: infrastructure_encryption_enabled
}
```

**Explanation:**
- This storage account has **3 security issues**:
  1. Non-geo-redundant replication (LRS instead of GRS/GZRS)
  2. Missing infrastructure encryption
  3. Missing diagnostic logging
  4. Missing soft delete (no blob_properties)

**What CloudSploit would find (AFTER deployment):**
- ❌ enable-geo-redundant-backups
- ❌ infrastructure-encryption-enabled
- ❌ storage-account-logging-enabled
- ❌ blobs-soft-deletion-enabled

---

### Step 2: Generate Terraform Plan JSON

```bash
# Initialize Terraform (no backend needed for testing)
terraform init -backend=false

# Create execution plan
terraform plan -out=tfplan.binary

# Convert binary plan to JSON (this is what REGO scans)
terraform show -json tfplan.binary > tfplan.json

# Verify JSON was created
ls -lh tfplan.json
```

**Explanation:**
- `tfplan.json` contains the **planned infrastructure state**
- This is what would be deployed to Azure
- REGO policy scans this JSON to find misconfigurations **before** deployment

**JSON Structure (simplified):**
```json
{
  "configuration": {
    "root_module": {
      "resources": [
        {
          "type": "azurerm_storage_account",
          "name": "bad_no_logging",
          "expressions": {
            "account_replication_type": {
              "constant_value": "LRS"  // ❌ Not geo-redundant
            }
            // ❌ Missing: infrastructure_encryption_enabled
            // ❌ Missing: blob_properties
          }
        }
      ]
    }
  }
}
```

---

### Step 3: Show the REGO Policy

```bash
# Show the soft delete check
cat azure-storage-misconfigurations.rego | grep -A 20 "blobs-soft-deletion-enabled"
```

**Output:**
```rego
# METADATA
# title: Azure Storage Account Must Have Soft Delete Enabled
# description: Blob soft deletion protects data from accidental deletion
# id: blobs-soft-deletion-enabled
# avd_id: AVD-AZU-0033
# severity: MEDIUM
deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.mode == "managed"

    not resource.expressions.blob_properties

    res := {
        "msg": sprintf("Storage account '%s' does not have blob soft delete enabled. Configure delete_retention_policy with at least 7 days.", [resource.name]),
        "severity": "MEDIUM",
        "id": "blobs-soft-deletion-enabled",
        "resource": resource.name
    }
}
```

**Explanation - Line by Line:**

```rego
deny[res] {
```
- Defines a rule that produces violations (adds to `deny` set)

```rego
    resource := input.configuration.root_module.resources[_]
```
- Iterates through all resources in Terraform plan JSON
- `_` is a wildcard that matches any array index

```rego
    resource.type == "azurerm_storage_account"
    resource.mode == "managed"
```
- Filters to only `azurerm_storage_account` resources
- Only checks managed resources (not data sources)

```rego
    not resource.expressions.blob_properties
```
- **The actual check**: blob_properties block is missing
- `not` means "this condition must be false to trigger violation"

```rego
    res := {
        "msg": sprintf("Storage account '%s' does not have blob soft delete enabled...", [resource.name]),
        "severity": "MEDIUM",
        "id": "blobs-soft-deletion-enabled",
        "resource": resource.name
    }
```
- Creates violation result with:
  - Human-readable message
  - Severity level
  - Check ID (maps to CloudSploit check)
  - Resource name for tracking

---

### Step 4: Run the REGO Policy with OPA

```bash
# Scan Terraform plan with REGO policy
~/opa eval \
  --data azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.deny' | head -50
```

**Output:**
```json
[
  {
    "id": "blobs-soft-deletion-enabled",
    "msg": "Storage account 'bad_no_logging' does not have blob soft delete enabled. Configure delete_retention_policy with at least 7 days.",
    "resource": "bad_no_logging",
    "severity": "MEDIUM"
  },
  {
    "id": "enable-geo-redundant-backups",
    "msg": "Storage account 'bad_no_logging' uses 'LRS' replication (not geo-redundant). Change to GRS, GZRS, RA-GRS, or RA-GZRS for disaster recovery.",
    "resource": "bad_no_logging",
    "severity": "HIGH"
  },
  {
    "id": "infrastructure-encryption-enabled",
    "msg": "Storage account 'bad_no_logging' does not have infrastructure encryption enabled. Set infrastructure_encryption_enabled = true for double encryption.",
    "resource": "bad_no_logging",
    "severity": "HIGH"
  }
]
```

**Explanation:**
- OPA found **27 total violations** across all storage accounts
- Each violation maps to a CloudSploit check
- These issues would normally be found **AFTER deployment**
- Now caught **BEFORE deployment** during `terraform plan`

---

### Step 5: Get Summary Statistics

```bash
# Get violation summary
~/opa eval \
  --data azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.violation_summary'
```

**Output:**
```json
{
  "by_severity": {
    "HIGH": 8,
    "LOW": 7,
    "MEDIUM": 12
  },
  "total_violations": 27
}
```

**Explanation:**
- 8 HIGH severity issues (infrastructure encryption, geo-redundancy)
- 12 MEDIUM severity issues (soft delete, diagnostic logging)
- 7 LOW severity issues (HTTPS not explicitly set)
- **This deployment would be BLOCKED** in production CI/CD

---

## 📋 Code Deep Dive - Advanced REGO Patterns

### Pattern 1: Missing Attribute Check

```rego
deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"

    # Check if attribute doesn't exist
    not resource.expressions.infrastructure_encryption_enabled

    res := {
        "msg": sprintf("Storage account '%s' missing infrastructure encryption", [resource.name]),
        "severity": "HIGH",
        "id": "infrastructure-encryption-enabled"
    }
}
```

**What this catches:**
```hcl
# ❌ VIOLATION - attribute not present
resource "azurerm_storage_account" "example" {
  name                     = "storageaccount"
  account_replication_type = "GRS"
  # Missing: infrastructure_encryption_enabled
}
```

---

### Pattern 2: Explicit False Value Check

```rego
deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"

    # Check if attribute is explicitly set to false
    resource.expressions.infrastructure_encryption_enabled.constant_value == false

    res := {
        "msg": sprintf("Storage account '%s' has encryption DISABLED", [resource.name]),
        "severity": "HIGH",
        "id": "infrastructure-encryption-enabled"
    }
}
```

**What this catches:**
```hcl
# ❌ VIOLATION - explicitly disabled
resource "azurerm_storage_account" "example" {
  name                              = "storageaccount"
  infrastructure_encryption_enabled = false  # Explicitly disabled
}
```

---

### Pattern 3: Threshold Check

```rego
deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"

    # Get nested value
    retention := resource.expressions.blob_properties[0].delete_retention_policy[0]
    days := retention.days.constant_value

    # Check if below threshold
    days < 7

    res := {
        "msg": sprintf("Storage account '%s' soft delete retention is %d days (minimum: 7)",
                      [resource.name, days]),
        "severity": "MEDIUM",
        "id": "blobs-soft-deletion-enabled"
    }
}
```

**What this catches:**
```hcl
# ❌ VIOLATION - retention too short
resource "azurerm_storage_account" "example" {
  blob_properties {
    delete_retention_policy {
      days = 3  # ❌ Less than 7 days
    }
  }
}
```

---

### Pattern 4: Enum Value Check (with Helper Function)

```rego
# Helper function to check geo-redundancy
is_geo_redundant(replication) {
    replication == "GRS"
}

is_geo_redundant(replication) {
    replication == "GZRS"
}

is_geo_redundant(replication) {
    replication == "RA-GRS"
}

is_geo_redundant(replication) {
    replication == "RA-GZRS"
}

# Main deny rule
deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"

    replication := resource.expressions.account_replication_type.constant_value

    # Use helper function
    not is_geo_redundant(replication)

    res := {
        "msg": sprintf("Storage account '%s' uses '%s' (not geo-redundant)",
                      [resource.name, replication]),
        "severity": "HIGH",
        "id": "enable-geo-redundant-backups"
    }
}
```

**What this catches:**
```hcl
# ❌ VIOLATION - not geo-redundant
resource "azurerm_storage_account" "example" {
  account_replication_type = "LRS"  # ❌ Locally redundant only
}

# ❌ VIOLATION - not geo-redundant
resource "azurerm_storage_account" "example2" {
  account_replication_type = "ZRS"  # ❌ Zone redundant only
}

# ✅ PASSES
resource "azurerm_storage_account" "good" {
  account_replication_type = "GRS"  # ✅ Geo-redundant
}
```

---

### Pattern 5: Cross-Resource Reference Check

```rego
deny[res] {
    # Find storage account
    storage_account := input.configuration.root_module.resources[_]
    storage_account.type == "azurerm_storage_account"
    storage_account_id := storage_account.address

    # Check if diagnostic setting exists that references this storage account
    not has_diagnostic_setting(storage_account_id)

    res := {
        "msg": sprintf("Storage account '%s' has no diagnostic logging",
                      [storage_account.name]),
        "severity": "MEDIUM",
        "id": "storage-account-logging-enabled"
    }
}

# Helper function to check for diagnostic setting
has_diagnostic_setting(storage_account_id) {
    diagnostic := input.configuration.root_module.resources[_]
    diagnostic.type == "azurerm_monitor_diagnostic_setting"

    # Check if target_resource_id references the storage account
    diagnostic.expressions.target_resource_id.references[0] == storage_account_id
}
```

**What this catches:**
```hcl
# ❌ VIOLATION - no diagnostic setting
resource "azurerm_storage_account" "example" {
  name = "storageaccount"
}
# Missing: azurerm_monitor_diagnostic_setting resource

# ✅ PASSES - has diagnostic setting
resource "azurerm_storage_account" "good" {
  name = "storageaccount"
}

resource "azurerm_monitor_diagnostic_setting" "logs" {
  name               = "storage-logs"
  target_resource_id = azurerm_storage_account.good.id  # ✅ References storage account

  enabled_log {
    category = "StorageRead"
  }
}
```

---

## 🔄 CloudSploit Check Mapping

### How REGO Checks Map to CloudSploit

| CloudSploit Check | REGO Policy ID | What It Detects | Example |
|-------------------|----------------|-----------------|---------|
| **blobs-soft-deletion-enabled** | `blobs-soft-deletion-enabled` | Missing `delete_retention_policy` or retention < 7 days | `blob_properties { }` (no delete policy) |
| **enable-geo-redundant-backups** | `enable-geo-redundant-backups` | `account_replication_type` not in GRS/GZRS/RA-GRS/RA-GZRS | `account_replication_type = "LRS"` |
| **infrastructure-encryption-enabled** | `infrastructure-encryption-enabled` | Missing or `infrastructure_encryption_enabled = false` | Not set or `= false` |
| **storage-account-logging-enabled** | `storage-account-logging-enabled` | Missing `azurerm_monitor_diagnostic_setting` | No diagnostic resource |
| **log-storage-encryption** | `log-storage-encryption` | Missing `enable_https_traffic_only = true` | Not explicitly set |
| **blob-container-cmk-encrypted** | `blob-container-cmk-encrypted` | Missing `customer_managed_key` block | No CMK configured |

---

## 🎬 Full Demo Script (Copy & Paste)

```bash
echo "=== Step 1: Show Misconfigured Terraform ==="
cd /Users/home/Developer/CBOM/research
cat azure-storage-test.tf | grep -A 10 "bad_no_logging"

echo "\n=== Step 2: Generate Terraform Plan JSON ==="
terraform init -backend=false
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
ls -lh tfplan.json

echo "\n=== Step 3: Show REGO Policy Check ==="
cat azure-storage-misconfigurations.rego | grep -A 15 "blobs-soft-deletion-enabled" | head -20

echo "\n=== Step 4: Run REGO Scan ==="
~/opa eval \
  --data azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.deny' | head -30

echo "\n=== Step 5: Get Summary ==="
~/opa eval \
  --data azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.violation_summary'

echo "\n✅ Demo Complete - 27 violations detected before deployment!"
```

---

## 💡 Key Talking Points for Demo

### 1. The Problem
> "CloudSploit scans our deployed Azure resources and finds storage misconfigurations. But by then, insecure storage accounts are already live in production. We need to catch these issues earlier."

### 2. The Solution
> "This custom REGO policy scans Terraform plan JSON during CI/CD. Same checks as CloudSploit, but runs BEFORE deployment. Zero production security gaps."

### 3. How It Works
> "REGO iterates through Terraform resources and checks for missing security configurations. For example, it verifies every storage account has geo-redundant replication, infrastructure encryption, and soft delete enabled."

### 4. The Results
> "In this demo, we scanned a test Terraform file with intentional violations. OPA found 27 issues across 6 different CloudSploit checks. In production, this would block the deployment until issues are fixed."

### 5. The Impact
> "Shift-left security. Developers get immediate feedback in their PR. Security team doesn't need to chase down post-deployment fixes. Azure never sees misconfigured storage accounts."

---

## 📊 Expected Demo Output

### Before (CloudSploit Runtime Detection):
```
Deployment Timeline:
├─ terraform apply ✅ (deployed)
├─ 2 hours later...
├─ CloudSploit scan ❌ (finds 27 issues)
└─ Create tickets, remediate, redeploy (1 week)
   Security gap: 1 week in production
```

### After (REGO Static Detection):
```
CI/CD Pipeline:
├─ terraform plan ✅
├─ OPA scan ❌ (finds 27 issues, blocks deployment)
├─ Developer fixes in 1 hour ✅
└─ Redeploy - secure from day 1
   Security gap: 0 days
```

---

## 🚀 Next Steps After Demo

1. **Integrate in GitHub Actions** (see REGO-TEST-SUCCESS.md for workflow YAML)
2. **Add to Terraform Cloud** as run task
3. **Extend to other Azure resources** (VMs, networks, databases)
4. **Share with team** - QUICK-START.md has copy-paste commands

---

**Files:**
- This demo guide: `DEMO-GUIDE.md`
- Test results: `REGO-TEST-SUCCESS.md`
- Quick commands: `QUICK-START.md`
- Full documentation: `REGO-POLICY-TESTING-RESULTS.md`

**Status**: ✅ Ready to demo
**Time**: 5-10 minutes
**Impact**: Shift-left CloudSploit findings to catch before deployment
