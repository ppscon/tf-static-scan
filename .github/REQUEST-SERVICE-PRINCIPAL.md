# Service Principal Request for Azure Admin

## Request Details

**Purpose:** Enable GitHub Actions to run Terraform security scans against Azure resources

**Project:** TF Static Scan - Terraform Security Scanner
**GitHub Repository:** https://github.com/ppscon/tf-static-scan

---

## Required Service Principal Configuration

### Basic Information
- **Name:** `tf-static-scan-github`
- **Description:** Service principal for GitHub Actions to run Terraform security scans
- **Type:** Application (App Registration)

### Required Permissions
- **Role:** Contributor
- **Scope:** `/subscriptions/71d0a3d0-ad98-4db0-b732-f95dc566a10a/resourceGroups/pp-rg`
- **Resource Group:** `pp-rg`
- **Subscription:** Aqua Customer Success (`71d0a3d0-ad98-4db0-b732-f95dc566a10a`)

### Access Requirements
The service principal needs to:
1. Read/write Azure Storage Accounts in resource group `pp-rg`
2. Access AKS cluster `pp-fips-cbom-demo` (optional - for advanced testing)
3. Create/delete test storage accounts for CI/CD pipeline testing

---

## Command for Azure Admin

Please run this command with admin privileges:

```bash
az ad sp create-for-rbac \
  --name "tf-static-scan-github" \
  --role contributor \
  --scopes /subscriptions/71d0a3d0-ad98-4db0-b732-f95dc566a10a/resourceGroups/pp-rg
```

---

## Required Output

Please provide the following values from the command output:

| Value from Output | Will be stored as GitHub Secret |
|------------------|----------------------------------|
| `appId` | AQUA_KEY and AQUA_USER |
| `password` | AQUA_PASSWORD |
| `tenant` | AQUA_SECRET |
| Subscription ID: `71d0a3d0-ad98-4db0-b732-f95dc566a10a` | AQUA_SERVER |

**Example output:**
```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "tf-static-scan-github",
  "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "tenant": "bc034cf3-566b-41ca-9f24-5dc49474b05e"
}
```

---

## Security Notes

✅ **Least Privilege:** Service principal has contributor access ONLY to resource group `pp-rg`
✅ **Scope Limited:** Cannot access other subscriptions or resource groups
✅ **Purpose-Built:** Used exclusively for automated security scanning in CI/CD
✅ **Auditable:** All actions logged in Azure Activity Log

---

## Alternative: Use Existing Service Principal

If you already have a service principal with access to `pp-rg`, you can use that instead.

**To find existing service principals:**
```bash
az ad sp list --show-mine --query "[].{Name:displayName, AppId:appId}" -o table
```

**To check permissions:**
```bash
az role assignment list \
  --assignee <appId> \
  --resource-group pp-rg \
  --output table
```

If an existing SP has Contributor role on `pp-rg`, just provide the credentials.

---

## Contact

**Requestor:** Philip Pearson
**Date:** 2025-10-08
**Use Case:** Automated Terraform security scanning with REGO policies in GitHub Actions

---

## Testing Plan

Once credentials are provided:

1. ✅ Store secrets in GitHub repository
2. ✅ Run basic workflow: `terraform-security-scan.yml` (no Azure access needed)
3. ✅ Run Azure integration: `azure-integration-test.yml` (requires service principal)
4. ✅ Validate scanning works correctly
5. ✅ Demo to team

---

## Questions?

See full documentation:
- Setup guide: `.github/SETUP-SECRETS.md`
- Workflow details: `.github/workflows/README.md`
- Project README: `README.md`
