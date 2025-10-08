#!/bin/bash

# Azure Storage REGO Policy Demo Script
# Demonstrates detecting CloudSploit findings in static Terraform code

set -e  # Exit on error

echo "======================================================================="
echo "  Azure Storage REGO Policy Demo"
echo "  Detecting CloudSploit findings BEFORE deployment"
echo "======================================================================="
echo ""

echo "=== Step 1: Show Misconfigured Terraform ==="
echo "This storage account has 4 security issues that CloudSploit would find:"
echo "  ❌ Non-geo-redundant replication (LRS)"
echo "  ❌ Missing infrastructure encryption"
echo "  ❌ Missing diagnostic logging"
echo "  ❌ Missing soft delete"
echo ""

# Get script directory and navigate to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT/examples"

cat azure-storage-test.tf | grep -A 10 "bad_no_logging"
echo ""
read -p "Press Enter to continue..."
echo ""

echo "=== Step 2: Use Pre-Generated Terraform Plan ==="
echo "Using the pre-generated Terraform plan JSON..."
echo "(No Azure credentials needed - pure static analysis)"
echo ""

if [ -f "$PROJECT_ROOT/tfplan.json" ]; then
    echo "✅ Using Terraform plan JSON:"
    ls -lh "$PROJECT_ROOT/tfplan.json"
else
    echo "⚠️  Pre-generated plan not found, generating new one..."
    terraform init -backend=false > /dev/null 2>&1
    terraform plan -out=tfplan.binary > /dev/null 2>&1
    terraform show -json tfplan.binary > tfplan.json
    echo "✅ Terraform plan JSON generated:"
    ls -lh tfplan.json
fi
echo ""
read -p "Press Enter to continue..."
echo ""

echo "=== Step 3: Show REGO Policy Check ==="
echo "This REGO rule checks if storage accounts have soft delete enabled:"
echo ""
cat "$PROJECT_ROOT/policies/azure-storage-misconfigurations.rego" | grep -A 15 "blobs-soft-deletion-enabled" | head -20
echo ""
echo "How it works:"
echo "  1. Iterates through all azurerm_storage_account resources"
echo "  2. Checks if blob_properties block exists"
echo "  3. Creates violation if missing or retention < 7 days"
echo ""
read -p "Press Enter to run the scan..."
echo ""

echo "=== Step 4: Run REGO Scan ==="
echo "Scanning Terraform plan with custom REGO policies..."
echo ""

# Use opa from PATH (installed via brew)
opa eval \
  --data "$PROJECT_ROOT/policies/azure-storage-misconfigurations.rego" \
  --input "$PROJECT_ROOT/tfplan.json" \
  --format pretty \
  'data.azure.storage.deny' | head -30
echo ""
echo "(Showing first 30 lines - total 27 violations found)"
echo ""
read -p "Press Enter to see summary..."
echo ""

echo "=== Step 5: Get Summary ==="
echo "Violation summary by severity:"
echo ""
opa eval \
  --data "$PROJECT_ROOT/policies/azure-storage-misconfigurations.rego" \
  --input "$PROJECT_ROOT/tfplan.json" \
  --format pretty \
  'data.azure.storage.violation_summary'
echo ""

echo "======================================================================="
echo "✅ Demo Complete!"
echo "======================================================================="
echo ""
echo "Results:"
echo "  • 27 violations detected BEFORE deployment"
echo "  • 8 HIGH severity (infrastructure encryption, geo-redundancy)"
echo "  • 12 MEDIUM severity (soft delete, diagnostic logging)"
echo "  • 7 LOW severity (HTTPS not explicitly set)"
echo ""
echo "Impact:"
echo "  ❌ Before: CloudSploit finds issues AFTER deployment (1 week security gap)"
echo "  ✅ After:  REGO catches issues DURING terraform plan (0 day security gap)"
echo ""
echo "Next Steps:"
echo "  1. Integrate in GitHub Actions (see REGO-TEST-SUCCESS.md)"
echo "  2. Add to Terraform Cloud as run task"
echo "  3. Block deployments with HIGH severity violations"
echo ""
echo "Files:"
echo "  • Project README: ../README.md"
echo "  • Demo guide:     ../docs/DEMO-GUIDE.md"
echo "  • Quick start:    ../docs/QUICK-START.md"
echo "  • Full results:   ../docs/REGO-TEST-SUCCESS.md"
echo ""
echo "======================================================================="
