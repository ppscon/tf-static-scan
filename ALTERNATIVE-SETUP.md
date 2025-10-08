# Alternative Setup - No Service Principal Required

Since you don't have permissions to create service principals, here are alternative approaches to test and demo the TF Static Scan:

---

## ✅ Option 1: GitHub Actions (No Azure Auth Required)

**Best for:** Automated testing, demos, CI/CD

### What's Available Now

The **Local Terraform Scan** workflow runs WITHOUT needing Azure credentials:
- File: `.github/workflows/local-terraform-scan.yml`
- Triggers: Pull requests, pushes to master, manual dispatch
- What it does: Scans Terraform examples and generates security reports

### How to Use

**View in GitHub:**
1. Go to: https://github.com/ppscon/tf-static-scan/actions
2. Select "Local Terraform Scan (No Azure Auth)"
3. Click "Run workflow"
4. See results in the workflow summary

**Expected Results:**
- 🔴 27 total violations detected
- 🔴 8 HIGH severity violations → Pipeline fails ✅
- 📊 Summary table with severity breakdown
- 📁 Artifacts with full scan results

---

## ✅ Option 2: Local Testing (Requires OPA)

**Best for:** Development, local testing

### Install OPA Locally

**macOS:**
```bash
brew install opa
```

**Linux:**
```bash
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
chmod +x opa
sudo mv opa /usr/local/bin/
```

### Run the Scan

```bash
cd /Users/home/Developer/tfscan
./run-scan.sh
```

**Expected Output:**
```
✅ OPA version: 0.x.x
📦 Initializing Terraform...
📋 Creating Terraform plan...
🔄 Converting plan to JSON...
🔍 Running security scan...
📊 Violation Summary: 27 violations (8 HIGH, 12 MEDIUM, 7 LOW)
❌ Found 8 HIGH severity violations
Policy would BLOCK deployment in CI/CD pipeline
```

---

## ✅ Option 3: Request Service Principal from Admin

**Best for:** Full Azure integration testing

### Send This Request

Use the template in `.github/REQUEST-SERVICE-PRINCIPAL.md` to request:
- Service principal with Contributor role on resource group `pp-rg`
- Or access to existing service principal with those permissions

Once you have the credentials, add them to GitHub secrets and the Azure workflows will work.

---

## ✅ Option 4: Use Azure Cloud Shell

**Best for:** Quick testing without local setup

### Steps

1. Open Azure Cloud Shell: https://shell.azure.com
2. Clone the repo:
   ```bash
   git clone https://github.com/ppscon/tf-static-scan.git
   cd tf-static-scan
   ```

3. Install OPA:
   ```bash
   wget https://openpolicyagent.org/downloads/latest/opa_linux_amd64 -O opa
   chmod +x opa
   sudo mv opa /usr/local/bin/
   ```

4. Run the scan:
   ```bash
   ./run-scan.sh
   ```

---

## Current Working Setup

### ✅ What Works NOW (No Azure Auth)

1. **GitHub Actions workflow** - `local-terraform-scan.yml`
   - Runs automatically on PR/push
   - Scans example Terraform files
   - Generates security reports
   - Fails on HIGH severity violations

2. **Local scan script** - `run-scan.sh`
   - Requires OPA installation
   - Runs security scan locally
   - Shows detailed violation results

3. **Example files** - `examples/azure-storage-test.tf`
   - Test Terraform with 27 intentional violations
   - Demonstrates all 6 security checks

### ⏳ What Needs Azure Auth (Optional)

1. **Azure Integration Test** - `azure-integration-test.yml`
   - Requires service principal credentials
   - Creates real Azure storage accounts for testing
   - Deploys to AKS cluster

---

## Recommended Demo Flow

### Without Azure Auth (Works Now!)

1. **Show GitHub Actions:**
   - Go to Actions tab: https://github.com/ppscon/tf-static-scan/actions
   - Run "Local Terraform Scan" workflow
   - Show summary with 27 violations detected

2. **Show Example Code:**
   - Open `examples/azure-storage-test.tf`
   - Point out intentional misconfigurations

3. **Show REGO Policy:**
   - Open `policies/azure-storage-misconfigurations.rego`
   - Explain security checks

4. **Show CI/CD Integration:**
   - Show how HIGH severity violations fail the pipeline
   - Demonstrate shift-left security

### With Azure Auth (Future)

Once you have service principal credentials:
1. Add secrets to GitHub
2. Run Azure integration workflow
3. Show real Azure resource creation
4. Deploy scanner to AKS cluster

---

## Summary

**Current Status:**
- ✅ Repository: https://github.com/ppscon/tf-static-scan
- ✅ Basic workflow: Working without Azure auth
- ✅ Local testing: Available (needs OPA install)
- ⏳ Azure integration: Needs service principal

**Next Steps:**
1. Install OPA locally OR use GitHub Actions
2. Test the scan: `./run-scan.sh` or run workflow manually
3. Demo the results
4. (Optional) Request service principal for Azure integration

---

**Questions? See:**
- Main README: `README.md`
- Workflow docs: `.github/workflows/README.md`
- Secret setup: `.github/SETUP-SECRETS.md`
- SP request: `.github/REQUEST-SERVICE-PRINCIPAL.md`
