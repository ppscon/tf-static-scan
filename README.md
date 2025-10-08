# TF Static Scan

Static security scanner for Terraform using REGO policies to detect Azure storage misconfigurations.

---

## 🎯 What This Does

Scans Terraform plan JSON files to detect security misconfigurations before deployment.

---

## 🚀 Quick Start

### Prerequisites
```bash
# Install OPA
brew install opa
```

### Basic Usage
```bash
# 1. Generate Terraform plan JSON
terraform init -backend=false
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# 2. Run scan
opa eval \
  --data policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.deny'

# 3. Get summary
opa eval \
  --data policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.violation_summary'
```

---

## 📦 What's Included

- **Policies** - REGO policies for Azure Storage security checks
- **Examples** - Sample Terraform configurations for testing
- **Tests** - Demo scripts and test cases

---

## 🔧 CI/CD Integration

### GitHub Actions
```yaml
- name: Terraform Plan
  run: |
    terraform plan -out=tfplan.binary
    terraform show -json tfplan.binary > tfplan.json

- name: Security Scan
  run: |
    opa eval \
      --data policies/azure-storage-misconfigurations.rego \
      --input tfplan.json \
      --format pretty \
      'data.azure.storage.deny'
```

---

## 📚 Learn More

- **Open Policy Agent:** https://www.openpolicyagent.org/
- **REGO Language:** https://www.openpolicyagent.org/docs/latest/policy-language/
