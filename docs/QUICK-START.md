# Quick Start - Azure Storage REGO Policy Testing

## ✅ Tested and Working - 27 violations detected

---

## Quick Test (Copy & Paste)

```bash
cd /Users/home/Developer/tfscan

# Test the policy
~/opa eval \
  --data policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.deny'

# Get summary
~/opa eval \
  --data policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.violation_summary'
```

**Expected Output**: 27 violations (8 HIGH, 12 MEDIUM, 7 LOW)

---

## Test on Your Own Terraform Code

```bash
# 1. Navigate to your Terraform directory
cd /path/to/your/terraform/code

# 2. Generate Terraform plan JSON
terraform init -backend=false
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# 3. Copy the REGO policy
cp /Users/home/Developer/tfscan/policies/azure-storage-misconfigurations.rego .

# 4. Run OPA scan
~/opa eval \
  --data azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.deny'
```

---

## Integration in CI/CD

### GitHub Actions

```yaml
- name: Terraform Plan
  run: |
    terraform init -backend=false
    terraform plan -out=tfplan.binary
    terraform show -json tfplan.binary > tfplan.json

- name: OPA Security Scan
  run: |
    curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
    chmod +x opa
    ./opa eval \
      --data azure-storage-misconfigurations.rego \
      --input tfplan.json \
      --format pretty \
      'data.azure.storage.deny' > violations.json

    # Fail if violations found
    VIOLATIONS=$(./opa eval \
      --data azure-storage-misconfigurations.rego \
      --input tfplan.json \
      --format raw \
      'data.azure.storage.violation_summary.total_violations')

    if [ "$VIOLATIONS" != "0" ]; then
      echo "❌ Found $VIOLATIONS violations"
      cat violations.json
      exit 1
    fi
```

---

## Files in This Directory

| File | Description |
|------|-------------|
| `azure-storage-test.tf` | Test Terraform with intentional violations |
| `azure-storage-misconfigurations.rego` | REGO policy (7 checks) |
| `tfplan.json` | Terraform plan JSON |
| `REGO-TEST-SUCCESS.md` | Detailed test results |
| `QUICK-START.md` | This file |

---

## Checks Included

1. ✅ **blobs-soft-deletion-enabled** (MEDIUM) - AVD-AZU-0033
2. ✅ **enable-geo-redundant-backups** (HIGH) - AVD-AZU-0038
3. ✅ **infrastructure-encryption-enabled** (HIGH) - AVD-AZU-0027
4. ✅ **blob-container-cmk-encrypted** (MEDIUM)
5. ✅ **storage-account-logging-enabled** (MEDIUM)
6. ✅ **log-storage-encryption** (HIGH/LOW) - AVD-AZU-0010

---

**Status**: ✅ Ready for production use
**Tested**: 2025-10-06
**Tool**: OPA CLI 0.11.0
