# TFScan - Terraform Security Scanner

**Shift-left CloudSploit findings into Terraform CI/CD with custom REGO policies**

Detect Azure storage misconfigurations **before deployment**, not after.

---

## 🎯 What This Does

Scans Terraform plan JSON with custom REGO policies to catch CloudSploit-equivalent security issues during CI/CD - **before they reach Azure**.

**Before (CloudSploit only):**
```
Deploy → CloudSploit scan (2hrs later) → Find issues → Create tickets → 1-2 week fix
Security gap: 1-2 weeks in production
```

**After (TFScan + CloudSploit):**
```
Terraform plan → TFScan with REGO → Block if issues → Developer fixes immediately
Security gap: 0 days
```

---

## ✅ What's Included

### Policies (`policies/`)
- **azure-storage-misconfigurations.rego** - 6 CloudSploit checks for Azure Storage:
  - ✅ blobs-soft-deletion-enabled (MEDIUM)
  - ✅ enable-geo-redundant-backups (HIGH)
  - ✅ infrastructure-encryption-enabled (HIGH)
  - ✅ storage-account-logging-enabled (MEDIUM)
  - ✅ log-storage-encryption (HIGH/LOW)
  - ✅ blob-container-cmk-encrypted (MEDIUM)

### Examples (`examples/`)
- **azure-storage-test.tf** - Test Terraform with intentional violations

### Documentation (`docs/`)
- **QUICK-START.md** - Quick commands to get started
- **DEMO-GUIDE.md** - Full demo with code explanations
- **DEMO-NARRATION.md** - Demo script with talking points
- **DEMO-CHEAT-SHEET.md** - Printable reference for presenting
- **REGO-TEST-SUCCESS.md** - Test results (27 violations found)
- **REGO-POLICY-TESTING-RESULTS.md** - Complete documentation

### Tests (`tests/`)
- **run-demo.sh** - Interactive demo script

---

## 🚀 Quick Start

### Prerequisites
```bash
# Install OPA
brew install opa

# Or download from: https://www.openpolicyagent.org/docs/latest/#running-opa
```

### Run the Demo
```bash
cd /Users/home/Developer/tfscan
./tests/run-demo.sh
```

### Test Against Your Terraform
```bash
# 1. Generate Terraform plan JSON
cd /path/to/your/terraform
terraform init -backend=false
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# 2. Run OPA scan
opa eval \
  --data /Users/home/Developer/tfscan/policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.deny'

# 3. Get summary
opa eval \
  --data /Users/home/Developer/tfscan/policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.violation_summary'
```

---

## 📊 Test Results

**Tested against `examples/azure-storage-test.tf`:**
- ✅ **27 violations detected**
  - 8 HIGH severity (encryption, geo-redundancy)
  - 12 MEDIUM severity (soft delete, logging)
  - 7 LOW severity (HTTPS not explicit)

**CloudSploit checks covered:** 6/7 storage account checks

---

## 🔧 CI/CD Integration

### GitHub Actions
```yaml
- name: Terraform Plan
  run: |
    terraform init -backend=false
    terraform plan -out=tfplan.binary
    terraform show -json tfplan.binary > tfplan.json

- name: TFScan Security Check
  run: |
    opa eval \
      --data policies/azure-storage-misconfigurations.rego \
      --input tfplan.json \
      --format raw \
      'data.azure.storage.violation_summary.total_violations'
```

See `docs/DEMO-NARRATION.md` for full GitHub Actions and Terraform Cloud integration examples.

---

## 📁 Project Structure

```
tfscan/
├── README.md                           # This file
├── policies/
│   └── azure-storage-misconfigurations.rego    # REGO policies
├── examples/
│   └── azure-storage-test.tf                   # Test Terraform
├── docs/
│   ├── QUICK-START.md                          # Quick reference
│   ├── DEMO-GUIDE.md                           # Full demo guide
│   ├── DEMO-NARRATION.md                       # Demo script
│   ├── DEMO-CHEAT-SHEET.md                     # Presenter cheat sheet
│   ├── REGO-TEST-SUCCESS.md                    # Test results
│   └── REGO-POLICY-TESTING-RESULTS.md          # Full documentation
├── tests/
│   └── run-demo.sh                             # Interactive demo
├── tfplan.json                                 # Sample Terraform plan
└── tfplan-formatted.json                       # Formatted for readability
```

---

## 🎬 Demo This Project

**Option 1: Interactive Demo (Recommended)**
```bash
./tests/run-demo.sh
```

**Option 2: Manual Demo**
1. Open `docs/DEMO-NARRATION.md` - Full talking points
2. Print `docs/DEMO-CHEAT-SHEET.md` - Keep next to keyboard
3. Follow the 5-step script with pauses

**Duration:** 8-10 minutes

---

## 📚 Documentation

- **Getting Started:** `docs/QUICK-START.md`
- **Demo Guide:** `docs/DEMO-GUIDE.md` (includes code explanations)
- **Demo Script:** `docs/DEMO-NARRATION.md` (what to say at each pause)
- **Cheat Sheet:** `docs/DEMO-CHEAT-SHEET.md` (printable reference)
- **Test Results:** `docs/REGO-TEST-SUCCESS.md`
- **Full Docs:** `docs/REGO-POLICY-TESTING-RESULTS.md`

---

## 🎯 Use Cases

### 1. Pre-Deployment Security Scanning
Catch misconfigurations during `terraform plan` before they reach Azure.

### 2. Pull Request Validation
Block PRs with HIGH severity violations automatically in CI/CD.

### 3. Compliance Auditing
Generate reports showing security posture of Terraform codebase.

### 4. Developer Education
Show developers what's wrong and how to fix it during development.

---

## 🔍 CloudSploit Mapping

| CloudSploit Check | TFScan Policy | Status |
|-------------------|---------------|--------|
| blobs-soft-deletion-enabled | ✅ Working | 4 violations found |
| enable-geo-redundant-backups | ✅ Working | 1 violation found |
| infrastructure-encryption-enabled | ✅ Working | 7 violations found |
| storage-account-logging-enabled | ✅ Working | 8 violations found |
| log-storage-encryption | ✅ Working | 7 violations found |
| blob-container-cmk-encrypted | ✅ Working | Ready |

---

## 🛠️ Extending This Project

### Add More Azure Resources
1. Create new REGO file in `policies/`
2. Follow the pattern in `azure-storage-misconfigurations.rego`
3. Add test cases to `examples/`

### Add More CloudSploit Checks
1. Identify CloudSploit check to implement
2. Add new `deny[res]` rule to existing REGO file
3. Test against sample Terraform

---

## 🤝 Contributing

This is an internal project. To contribute:
1. Create feature branch
2. Add/modify REGO policies
3. Test thoroughly
4. Submit PR with test results

---

## 📞 Support

- **Slack:** #security-rego-support
- **Documentation:** `/Users/home/Developer/tfscan/docs/`
- **Demo Questions:** See `DEMO-CHEAT-SHEET.md`

---

## ✅ Status

**Project Status:** ✅ Ready for demo and pilot implementation

**Last Updated:** 2025-10-07

**Tested On:**
- OPA 0.11.0
- Terraform 1.5+
- Azure Provider 3.0+

---

## 🎓 Learn More

- **Open Policy Agent:** https://www.openpolicyagent.org/
- **REGO Language:** https://www.openpolicyagent.org/docs/latest/policy-language/
- **CloudSploit:** https://github.com/aquasecurity/cloudsploit
- **Aqua Trivy:** https://github.com/aquasecurity/trivy

---

**Built with ❤️ to shift-left CloudSploit findings**
