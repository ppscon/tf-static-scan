# Service Principal Request

**Project:** TF Static Scan - Terraform Security Scanner
**Purpose:** Enable GitHub Actions CI/CD pipeline to run security scans

---

## Request

Please create a service principal with the following configuration:

**Name:** `tf-static-scan-github`

**Scope:**
- Resource Group: `pp-rg`
- Subscription: `Aqua Customer Success` (71d0a3d0-ad98-4db0-b732-f95dc566a10a)

**Role:** Reader (read-only access on resource group `pp-rg`)

**Command:**
```bash
az ad sp create-for-rbac \
  --name "tf-static-scan-github" \
  --role reader \
  --scopes /subscriptions/71d0a3d0-ad98-4db0-b732-f95dc566a10a/resourceGroups/pp-rg
```

---

## Required Output

Please provide the output values so I can configure GitHub Actions:

- `appId`
- `password`
- `tenant`

---

## Use Case

The service principal will be used by GitHub Actions to:
1. Authenticate Terraform provider for static analysis
2. Generate Terraform plans for security scanning
3. Run REGO policy checks against infrastructure code

**Note:** Only READ access is required - no resources will be created or modified.

---

**Requestor:** Philip Pearson
**Repository:** https://github.com/ppscon/tf-static-scan
