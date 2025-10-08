# Demo TF Static Scan Without Azure Credentials

**Good news:** You can fully demo and test TF Static Scan RIGHT NOW without waiting for Azure credentials!

---

## ✅ What Works WITHOUT Azure Credentials

### 1. **Local Static Scanning** (Recommended)

Use the pre-generated `tfplan.json` file to demonstrate the scanner:

```bash
cd /Users/home/Developer/tfscan

# Interactive demo with explanations
./demo-local.sh

# Quick scan
opa eval \
  --data policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.deny'

# Get summary
opa eval \
  --data policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.violation_summary'
```

**Expected Results:**
- ✅ 27 violations detected
- ✅ 8 HIGH, 12 MEDIUM, 7 LOW
- ✅ Policy blocks deployment
- ✅ ~5 seconds to complete

---

### 2. **Show the REGO Policies**

Open and explain the security checks:

```bash
# View the policy file
code policies/azure-storage-misconfigurations.rego

# Or view in terminal
cat policies/azure-storage-misconfigurations.rego
```

**Security Checks Included:**
1. Blob soft delete enabled (MEDIUM)
2. Geo-redundant replication (HIGH)
3. Infrastructure encryption (HIGH)
4. Customer-managed keys (MEDIUM)
5. Diagnostic logging (MEDIUM)
6. HTTPS enforcement (HIGH/LOW)

---

### 3. **Show the Terraform Test Code**

Display the intentional misconfigurations:

```bash
# View test Terraform
code examples/azure-storage-test.tf

# Or in terminal
cat examples/azure-storage-test.tf
```

Points to highlight:
- Shows both BAD and GOOD configurations
- Demonstrates what triggers each policy violation
- Clear comments explain each issue

---

### 4. **Show the GitHub Repository**

Share the public repo:
- **URL:** https://github.com/ppscon/tf-static-scan
- Shows modern REGO syntax (OPA 1.9+)
- Includes GitHub Actions workflows
- Complete documentation

---

## 🎬 Demo Script (5 Minutes)

### Slide 1: The Problem (30 seconds)
*"Currently, CloudSploit finds storage misconfigurations AFTER deployment, creating a 1-2 week security gap while issues are remediated."*

### Slide 2: The Solution (30 seconds)
*"TF Static Scan detects the SAME issues during terraform plan, BEFORE deployment - reducing the security gap to zero days."*

### Slide 3: Live Demo (3 minutes)

```bash
cd /Users/home/Developer/tfscan

# Show the scan
opa eval \
  --data policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.violation_summary'
```

**Walk through:**
1. Point out: 27 violations detected in seconds
2. Show: Breakdown by severity (HIGH/MEDIUM/LOW)
3. Explain: HIGH severity = deployment blocked
4. Compare: CloudSploit finds these 2 hours AFTER deploy

### Slide 4: Sample Violations (1 minute)

```bash
# Show first few violations
opa eval \
  --data policies/azure-storage-misconfigurations.rego \
  --input tfplan.json \
  --format pretty \
  'data.azure.storage.deny' | head -20
```

Point out:
- Clear error messages
- Specific resource names
- Actionable remediation guidance

### Slide 5: Impact (30 seconds)
*"Shift-left security: catch issues at development time, not in production. Zero-day security gap vs 1-2 weeks."*

---

## 💡 Key Demo Points

### For Security Teams:
✅ Detects CloudSploit-equivalent issues pre-deployment
✅ Maps to AVD (Azure Vulnerability Database) IDs
✅ Customizable policies (add more checks easily)
✅ Integrates with existing CI/CD pipelines

### For DevOps Teams:
✅ Fails pipeline on HIGH severity issues
✅ Fast feedback (seconds, not hours)
✅ Works with Terraform plan (no deployment needed)
✅ Clear error messages for quick fixes

### For Management:
✅ Reduces security remediation time: 1-2 weeks → 0 days
✅ Prevents misconfigurations from reaching production
✅ Uses open-source tools (OPA - industry standard)
✅ Zero additional infrastructure required

---

## 📊 Test Results to Share

**What the scanner detects:**
```
Total Violations: 27
├── HIGH: 8 (blocks deployment)
│   ├── Missing geo-redundant replication
│   ├── Infrastructure encryption disabled
│   └── HTTPS not enforced
├── MEDIUM: 12
│   ├── Soft delete not configured
│   ├── Diagnostic logging missing
│   └── CMK encryption not enabled
└── LOW: 7
    └── HTTPS not explicitly set
```

---

## 🚀 What Azure Credentials Will Add (Later)

Once you have the service principal:

1. **Real Terraform Plan Generation**
   - Scan your actual Azure Terraform repositories
   - Test against live infrastructure code

2. **GitHub Actions Integration**
   - Automatic scanning on every PR
   - Block deployments with violations

3. **Azure DevOps Integration**
   - Pipeline integration
   - Automated compliance reports

**But you don't need this to demo the concept!** The static analysis works perfectly with the pre-generated plan.

---

## 📝 Quick Reference

**Local demo:**
```bash
./demo-local.sh
```

**Quick scan:**
```bash
opa eval --data policies/azure-storage-misconfigurations.rego \
  --input tfplan.json --format pretty 'data.azure.storage.deny'
```

**View policies:**
```bash
code policies/azure-storage-misconfigurations.rego
```

**GitHub repo:**
https://github.com/ppscon/tf-static-scan

---

## ✅ You're Ready to Demo!

Everything works right now without Azure credentials. The service principal will just add convenience for scanning real Terraform repos later.

**Start here:**
```bash
cd /Users/home/Developer/tfscan
./demo-local.sh
```
