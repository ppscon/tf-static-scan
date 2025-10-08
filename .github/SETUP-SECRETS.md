# GitHub Secrets Setup Guide

## Required Secrets

The following secrets need to be configured in your GitHub repository for the workflows to function.

### Azure Authentication Secrets

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `AQUA_KEY` | Azure Service Principal App ID | Output from `az ad sp create-for-rbac` |
| `AQUA_PASSWORD` | Azure Service Principal Password | Output from `az ad sp create-for-rbac` |
| `AQUA_SECRET` | Azure Tenant ID | Output from `az ad sp create-for-rbac` |
| `AQUA_SERVER` | Azure Subscription ID | `71d0a3d0-ad98-4db0-b732-f95dc566a10a` |
| `AQUA_USER` | Azure Service Principal App ID | Same as AQUA_KEY |
| `AQUA_TOKEN` | GitHub Personal Access Token | For GitHub API access (optional) |

---

## Step 1: Create Azure Service Principal

Run this command to create a service principal with access to your resource group:

```bash
az ad sp create-for-rbac \
  --name "tf-static-scan-github" \
  --role contributor \
  --scopes /subscriptions/71d0a3d0-ad98-4db0-b732-f95dc566a10a/resourceGroups/pp-rg
```

**Output Example:**
```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "tf-static-scan-github",
  "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "tenant": "bc034cf3-566b-41ca-9f24-5dc49474b05e"
}
```

---

## Step 2: Map Output to GitHub Secrets

Take the output from Step 1 and create these secrets:

### In GitHub Repository Settings → Secrets → Actions:

1. **AQUA_KEY**
   - Value: Copy `appId` from output

2. **AQUA_PASSWORD**
   - Value: Copy `password` from output

3. **AQUA_SECRET**
   - Value: Copy `tenant` from output
   - Or use: `bc034cf3-566b-41ca-9f24-5dc49474b05e`

4. **AQUA_SERVER**
   - Value: `71d0a3d0-ad98-4db0-b732-f95dc566a10a`

5. **AQUA_USER**
   - Value: Same as AQUA_KEY (the `appId`)

6. **AQUA_TOKEN** (Optional)
   - Value: GitHub Personal Access Token
   - Only needed if workflows require GitHub API access beyond standard permissions

---

## Step 3: Verify Service Principal Permissions

Check that the service principal has correct access:

```bash
# Using the appId from the output
az role assignment list \
  --assignee <appId> \
  --resource-group pp-rg \
  --output table
```

Expected output should show `Contributor` role on the resource group.

---

## Step 4: Test Authentication

Test the service principal login:

```bash
az login --service-principal \
  --username <appId> \
  --password <password> \
  --tenant <tenant>

az account show
```

---

## Alternative: Use Existing Service Principal

If you already have a service principal, you can use it instead:

```bash
# List existing service principals
az ad sp list --display-name "your-sp-name" --output table

# Get credentials (if you have them stored)
# Then map to the GitHub secrets as described in Step 2
```

---

## Security Notes

⚠️ **Important:**
- Never commit these secrets to git
- Rotate service principal passwords periodically
- Use least-privilege access (contributor only on specific resource group)
- Monitor service principal usage in Azure Activity Log

---

## Quick Reference

**Resource Group:** `pp-rg`
**Subscription ID:** `71d0a3d0-ad98-4db0-b732-f95dc566a10a`
**Tenant ID:** `bc034cf3-566b-41ca-9f24-5dc49474b05e`
**AKS Cluster:** `pp-fips-cbom-demo`
**Location:** `eastus`
