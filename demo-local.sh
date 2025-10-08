#!/bin/bash

# TF Static Scan - Local Demo (No Azure Required)
# This demonstrates the security scanning without any Azure credentials

set -e

echo "=========================================="
echo "🔒 TF Static Scan - Local Demo"
echo "=========================================="
echo ""
echo "This demo shows how the scanner detects"
echo "Azure storage misconfigurations in Terraform"
echo "code BEFORE deployment (shift-left security)."
echo ""
echo "No Azure credentials needed - pure static analysis!"
echo ""
echo "=========================================="
echo ""

# Check OPA
if ! command -v opa &> /dev/null; then
    echo "❌ OPA not found. Installing..."
    echo ""
    brew install opa
fi

echo "✅ OPA Version: $(opa version | head -1)"
echo ""

# Use the pre-generated tfplan.json
if [ ! -f "tfplan.json" ]; then
    echo "❌ tfplan.json not found"
    echo "Please run this from the project root directory"
    exit 1
fi

echo "📁 Using pre-generated Terraform plan: tfplan.json"
echo ""
echo "This plan contains INTENTIONAL misconfigurations to demonstrate"
echo "the scanner's capabilities."
echo ""
echo "Press ENTER to see detected violations..."
read

echo "=========================================="
echo "🔍 Running Security Scan..."
echo "=========================================="
echo ""

opa eval \
  --data policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.deny'

echo ""
echo "=========================================="
echo "📊 Violation Summary"
echo "=========================================="
echo ""

opa eval \
  --data policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.violation_summary'

echo ""

# Check HIGH severity
HIGH_COUNT=$(opa eval \
  --data policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format raw \
  'count([v | v := data.azure.storage.deny[_]; v.severity == "HIGH"])')

echo "=========================================="
echo "🚦 Policy Decision"
echo "=========================================="
echo ""

if [ "$HIGH_COUNT" -gt 0 ]; then
    echo "❌ BLOCK DEPLOYMENT"
    echo ""
    echo "Found $HIGH_COUNT HIGH severity violations"
    echo ""
    echo "In a CI/CD pipeline, this would:"
    echo "  • Fail the pipeline"
    echo "  • Block the pull request"
    echo "  • Prevent deployment to Azure"
    echo "  • Notify the developer to fix issues"
else
    echo "✅ ALLOW DEPLOYMENT"
    echo ""
    echo "No HIGH severity violations found"
    echo "Deployment can proceed safely"
fi

echo ""
echo "=========================================="
echo "💡 Key Takeaway"
echo "=========================================="
echo ""
echo "This scan happened in SECONDS, not hours!"
echo ""
echo "Traditional approach:"
echo "  Deploy → CloudSploit finds issues (2 hrs later)"
echo "  → 1-2 week remediation"
echo ""
echo "TF Static Scan:"
echo "  Terraform plan → Scan (30 seconds)"
echo "  → Block bad code → Fix immediately"
echo ""
echo "Security gap: 1-2 weeks → 0 days ✨"
echo ""
echo "=========================================="
