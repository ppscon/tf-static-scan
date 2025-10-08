# TF Static Scan

Static security scanner for Terraform using REGO policies to detect Azure storage misconfigurations.

---

## 🎯 What This Does

Scans Terraform plan JSON files to detect security misconfigurations before deployment.

---

## 🚀 Quick Start

### Prerequisites

**Local Testing (macOS/Linux):**
```bash
# Install OPA
brew install opa
```

**CI/CD Pipeline (Linux):**
```bash
# Download OPA binary
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
chmod +x opa
```

**Azure DevOps / Cloud Shell:**
```bash
# Download OPA
wget https://openpolicyagent.org/downloads/latest/opa_linux_amd64 -O opa
chmod +x opa
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
    curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
    chmod +x opa
    ./opa eval \
      --data policies/azure-storage-misconfigurations.rego \
      --input tfplan.json \
      --format pretty \
      'data.azure.storage.deny'
```

### Azure DevOps Pipeline
```yaml
- task: Bash@3
  displayName: 'Terraform Plan'
  inputs:
    targetType: 'inline'
    script: |
      terraform plan -out=tfplan.binary
      terraform show -json tfplan.binary > tfplan.json

- task: Bash@3
  displayName: 'Security Scan'
  inputs:
    targetType: 'inline'
    script: |
      wget https://openpolicyagent.org/downloads/latest/opa_linux_amd64 -O opa
      chmod +x opa
      ./opa eval \
        --data $(System.DefaultWorkingDirectory)/policies/azure-storage-misconfigurations.rego \
        --input tfplan.json \
        --format pretty \
        'data.azure.storage.deny'
```

---

## 📚 Learn More

- **Open Policy Agent:** https://www.openpolicyagent.org/
- **REGO Language:** https://www.openpolicyagent.org/docs/latest/policy-language/
