#!/bin/bash

# TF Static Scan - Local Test Runner
# This script runs the security scan locally without needing Azure credentials

set -e

echo "🔍 TF Static Scan - Local Test Runner"
echo "======================================"
echo ""

# Check if OPA is installed
if ! command -v opa &> /dev/null; then
    echo "❌ OPA is not installed."
    echo ""
    echo "Install with: brew install opa"
    echo "Or download from: https://www.openpolicyagent.org/downloads/"
    exit 1
fi

echo "✅ OPA version: $(opa version | head -1)"
echo ""

# Navigate to examples directory
cd examples

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init -backend=false > /dev/null

# Create plan
echo "📋 Creating Terraform plan..."
terraform plan -out=tfplan.binary > /dev/null

# Convert to JSON
echo "🔄 Converting plan to JSON..."
terraform show -json tfplan.binary > tfplan.json

# Run OPA scan
echo ""
echo "🔍 Running security scan..."
echo "======================================"
echo ""

opa eval \
  --data ../policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.deny'

echo ""
echo "======================================"
echo ""

# Get summary
echo "📊 Violation Summary:"
echo ""

opa eval \
  --data ../policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.violation_summary'

echo ""

# Check for HIGH severity
HIGH_COUNT=$(opa eval \
  --data ../policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format raw \
  'count([v | v := data.azure.storage.deny[_]; v.severity == "HIGH"])')

echo ""
echo "======================================"
if [ "$HIGH_COUNT" -gt 0 ]; then
    echo "❌ Found $HIGH_COUNT HIGH severity violations"
    echo ""
    echo "Policy would BLOCK deployment in CI/CD pipeline"
    exit 1
else
    echo "✅ No HIGH severity violations found"
    echo ""
    echo "Policy would ALLOW deployment in CI/CD pipeline"
fi

echo "======================================"
