# Azure Storage REGO Policy Demo - Narration Script

**Duration**: 8-10 minutes
**Audience**: Security team, DevOps, Platform engineering
**Objective**: Show how to shift-left CloudSploit findings into Terraform CI/CD

---

## 📖 Quick Reference - REGO Concepts for You

**Before you start the demo, familiarize yourself with these key concepts:**

### What is REGO?
- Policy language from Open Policy Agent (OPA)
- **Declarative** = You describe WHAT to find, not HOW to find it (like SQL)
- Works by pattern matching against JSON input

### REGO Rule Structure (The Pattern You'll Explain):
```
deny[result] {              ← "Create a violation called result"
    resource := input...    ← "Loop through all resources"
    resource.type == "..."  ← "Filter to specific type"
    not resource.field      ← "Check: is something missing/wrong?"
    result := { ... }       ← "Build the violation message"
}
```

### Key REGO Syntax Elements:
- **`:=`** = Assignment ("set this variable to...")
- **`==`** = Comparison ("is this equal to?")
- **`[_]`** = Wildcard ("any element in the array")
- **`not`** = Negation ("if this doesn't exist")
- **`deny[...]`** = Creates a violation set

### The Six Checks You Built:
1. ✅ **blobs-soft-deletion-enabled** - Checks for `blob_properties.delete_retention_policy`
2. ✅ **enable-geo-redundant-backups** - Checks `account_replication_type` is GRS/GZRS/RA-GRS/RA-GZRS
3. ✅ **infrastructure-encryption-enabled** - Checks `infrastructure_encryption_enabled = true`
4. ✅ **storage-account-logging-enabled** - Checks for `azurerm_monitor_diagnostic_setting` resource
5. ✅ **log-storage-encryption** - Checks `enable_https_traffic_only = true`
6. ✅ **blob-container-cmk-encrypted** - Checks for `customer_managed_key` block

### Analogy Library (Use These If Asked Questions):
- **"What's REGO like?"** → "It's like SQL for policies - you describe patterns, it finds matches"
- **"Why not just use Python?"** → "REGO is declarative and sandboxed - safer for policy enforcement"
- **"How does it scan Terraform?"** → "It reads the JSON plan - the exact config that would be deployed"
- **"Can we customize it?"** → "Absolutely - each rule is independent, easy to add/modify"

---

## 🎬 Demo Narration - What to Say at Each Pause

### Opening (Before Starting Script)

> "Hi everyone, thanks for joining. Today I want to show you how we can detect CloudSploit security findings **before** they get deployed to Azure, not after.
>
> The problem we're solving: CloudSploit scans our Azure environment and finds storage misconfigurations - things like missing encryption, no geo-redundancy, soft delete disabled. But by the time CloudSploit finds these issues, they're already live in production. We then have to create tickets, remediate, redeploy - which can take days or weeks.
>
> What I'm going to show you is how we can catch these exact same issues during the Terraform planning phase, before anything gets deployed. Let me show you how this works..."

**[START THE SCRIPT: `./run-demo.sh`]**

---

### 📍 PAUSE 1: After Step 1 (Misconfigured Terraform)

**Screen shows:**
```hcl
resource "azurerm_storage_account" "bad_no_logging" {
  name                     = "storagenologging"
  account_replication_type = "LRS"
  ...
}
```

**What to say:**

> "So here's a typical Terraform storage account configuration. Looks innocent enough, right? But this has **four security issues** that CloudSploit would flag:
>
> 1. **LRS replication** - that's locally redundant, not geo-redundant. If the Azure region goes down, all data is lost.
> 2. **No infrastructure encryption** - missing that second layer of encryption at rest.
> 3. **No diagnostic logging** - we can't audit who's accessing this storage.
> 4. **No soft delete** - if someone accidentally deletes blobs, they're gone forever.
>
> Normally, a developer would push this code, it goes through CI/CD, gets deployed to Azure, and then 2 hours later CloudSploit runs and finds all these issues. That's a security gap.
>
> What we're going to do is catch these issues **right here** during the Terraform plan phase, before it ever reaches Azure."

**[PRESS ENTER]**

---

### 📍 PAUSE 2: After Step 2 (Terraform Plan JSON)

**Screen shows:**
```
✅ Terraform plan JSON generated:
-rw-r--r--  1 home  staff  123456 Oct  6 18:21 tfplan.json
```

**What to say:**

> "What we just did is generate a Terraform plan - this is the JSON representation of what Terraform **would** deploy to Azure. It contains all the resource configurations, all the attributes, everything.
>
> This JSON file is the key. Instead of deploying first and scanning later, we're going to scan **this plan** before deployment.
>
> Think of it like a pre-flight checklist for pilots. We're checking everything is safe before takeoff, not after we're already in the air.
>
> The beauty of this approach is we're scanning the **exact configuration** that would be deployed. No guessing, no drift - we see exactly what's wrong before it becomes a problem."

**[PRESS ENTER]**

---

### 📍 PAUSE 3: After Step 3 (REGO Policy)

**Screen shows:**
```rego
# METADATA
# title: Azure Storage Account Must Have Soft Delete Enabled
# description: Blob soft deletion protects data from accidental deletion
# id: blobs-soft-deletion-enabled
# avd_id: AVD-AZU-0033
# severity: MEDIUM
deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.mode == "managed"

    not resource.expressions.blob_properties

    res := {
        "msg": sprintf("Storage account '%s' does not have blob soft delete enabled. Configure delete_retention_policy with at least 7 days.", [resource.name]),
        "severity": "MEDIUM",
        "id": "blobs-soft-deletion-enabled",
        "resource": resource.name
    }
}
```

**YOUR CHEAT SHEET (what each line means):**
- **Lines 1-6**: Metadata (title, description, severity) - just documentation
- **Line 7**: `deny[res] {` - This defines a rule that adds violations to the "deny" collection
- **Line 8**: `resource := input.configuration.root_module.resources[_]` - Loop through ALL resources in the Terraform plan
- **Line 9**: `resource.type == "azurerm_storage_account"` - Filter: only look at Azure storage accounts
- **Line 10**: `resource.mode == "managed"` - Filter: only resources we create (not data sources)
- **Line 12**: `not resource.expressions.blob_properties` - **THE KEY CHECK**: Is blob_properties missing?
- **Lines 14-19**: Create the violation report with message, severity, ID, resource name

**What to say:**

> "Okay, now let me show you the REGO policy - this is the actual rule that detects the soft delete issue. I know REGO can look intimidating at first, but it's actually pretty straightforward once you understand the pattern.
>
> REGO is the policy language from Open Policy Agent. Think of it like SQL for policies - you describe what you're looking for, and OPA finds it.
>
> Let me break this down in plain English:
>
> **[Point to top of screen - metadata section]**
> First, we have metadata up here - title, description, the CloudSploit check ID it maps to, and severity level. That's just documentation.
>
> **[Point to 'deny[res] {' line]**
> This line says 'I'm going to define a rule that creates violations.' The word 'deny' means if this rule matches, we block it.
>
> **[Point to 'resource := input...' line]**
> Here we're saying 'Loop through ALL resources in the Terraform plan.' The underscore is a wildcard - it matches any resource, any index.
>
> **[Point to 'resource.type ==' line]**
> Now we filter down - we only care about Azure storage accounts. So if Terraform has 50 resources but only 5 are storage accounts, we only check those 5.
>
> **[Point to 'resource.mode ==' line]**
> This line filters out data sources - we only want to check resources we're actually creating or managing.
>
> **[Point to 'not resource.expressions.blob_properties' line]**
> And THIS is the heart of the check. We're asking: 'Is the blob_properties block missing?' The word 'not' means 'if this doesn't exist.' So if a storage account doesn't have blob_properties configured, that means no soft delete, and we flag it as a violation.
>
> **[Point to 'res := {' section]**
> Finally, if we found a violation, we create a structured result - a human-readable message explaining what's wrong, the severity level, which CloudSploit check this maps to, and which specific resource is the problem.
>
> **[Broader point]**
> I've written six of these rules total - one for each CloudSploit check we want to shift left:
> - Soft delete enabled ✓
> - Geo-redundant replication ✓
> - Infrastructure encryption ✓
> - Diagnostic logging ✓
> - HTTPS enforcement ✓
> - Customer-managed keys ✓
>
> Each rule follows this exact same pattern: loop through resources, filter to the type we care about, check if something's missing or wrong, create a violation if it is.
>
> The beauty of REGO is it's declarative - I don't have to write loops and if-statements. I just describe the bad pattern, and OPA finds every instance of it across my entire Terraform codebase.
>
> Now let's see this in action - let's run it against our Terraform plan and see what violations it finds..."

**[PRESS ENTER]**

---

### 📍 PAUSE 4: After Step 4 (REGO Scan Results)

**Screen shows:**
```json
[
  {
    "id": "blobs-soft-deletion-enabled",
    "msg": "Storage account 'bad_no_logging' does not have blob soft delete enabled...",
    "severity": "MEDIUM"
  },
  {
    "id": "enable-geo-redundant-backups",
    "msg": "Storage account 'bad_no_logging' uses 'LRS' replication (not geo-redundant)...",
    "severity": "HIGH"
  },
  ...
]
```

**What to say:**

> "And here we go - violations detected! Look at this output.
>
> **First violation**: 'Storage account bad_no_logging does not have blob soft delete enabled' - that's the CloudSploit check `blobs-soft-deletion-enabled`, mapped directly into our REGO policy. Medium severity.
>
> **Second violation**: 'Uses LRS replication not geo-redundant' - that's `enable-geo-redundant-backups` from CloudSploit. High severity because data loss risk.
>
> **Third violation**: 'Missing infrastructure encryption' - another high severity issue.
>
> These are the **exact same findings** CloudSploit would report, but we're catching them during `terraform plan`, not after deployment.
>
> I'm showing you the first 30 lines here, but we actually found **27 total violations** across the test file. Let me show you the summary..."

**[PRESS ENTER]**

---

### 📍 PAUSE 5: After Step 5 (Summary)

**Screen shows:**
```json
{
  "by_severity": {
    "HIGH": 8,
    "LOW": 7,
    "MEDIUM": 12
  },
  "total_violations": 27
}
```

**What to say:**

> "Here's the summary - **27 violations detected before deployment**.
>
> Breaking it down by severity:
> - **8 HIGH severity** - these are critical issues like missing encryption and no disaster recovery. In production, these would be blockers.
> - **12 MEDIUM severity** - things like missing soft delete and diagnostic logging. Important security controls.
> - **7 LOW severity** - HTTPS not explicitly enforced (it defaults to true, but best practice is to set it explicitly).
>
> In a real CI/CD pipeline, we'd configure this to **block the deployment** if any HIGH severity violations are found. The developer gets immediate feedback in their pull request - 'Hey, you need to enable geo-redundancy before this can merge.'
>
> Compare that to the old way: deploy first, CloudSploit finds issues 2 hours later, create tickets, wait for next sprint, remediate, redeploy. That could be a **1-2 week security gap** in production.
>
> With this approach? **Zero day security gap**. Issues never reach Azure."

**[DEMO COMPLETES - Shows final summary screen]**

---

## 🎯 Closing Summary (After Demo)

> "So to recap what we just saw:
>
> **Before** (CloudSploit only):
> - Developer → Git push → CI/CD → Deploy to Azure → CloudSploit scan (2 hours later) → Find 27 issues → Create tickets → 1-2 week remediation cycle
> - **Security gap: 1-2 weeks in production**
>
> **After** (REGO + CloudSploit):
> - Developer → Git push → CI/CD → Terraform plan → OPA scan (30 seconds) → Find 27 issues → Block deployment → Developer fixes immediately
> - **Security gap: 0 days**
>
> CloudSploit still runs on deployed resources - that's our safety net. But now we're catching 90% of issues before they ever reach Azure.
>
> This is true shift-left security."

---

## 💼 Business As Usual (BAU) Implementation Guide

### Phase 1: Proof of Concept (Weeks 1-2)

**Goal**: Validate in non-production environment

**Actions**:
1. **Test REGO policies against existing Terraform**
   ```bash
   # Scan dev/test Terraform repos
   cd terraform/dev
   terraform plan -out=tfplan.binary
   terraform show -json tfplan.binary > tfplan.json
   opa eval --data azure-storage-misconfigurations.rego --input tfplan.json 'data.azure.storage.deny'
   ```

2. **Calibrate severity levels and false positives**
   - Review findings with security team
   - Adjust REGO rules if needed (e.g., some storage accounts legitimately use LRS)
   - Create exemption patterns if necessary

3. **Document baseline violations**
   - Run against all existing Terraform
   - Create backlog of remediation items
   - Decide: fix before enabling enforcement, or grandfather existing resources?

**Deliverables**:
- ✅ REGO policies tested against 5+ Terraform repositories
- ✅ False positive rate < 5%
- ✅ Baseline violation report
- ✅ Go/no-go decision for Phase 2

---

### Phase 2: Advisory Mode (Weeks 3-4)

**Goal**: Integrate into CI/CD in **non-blocking mode** (warnings only)

**GitHub Actions Implementation**:

```yaml
# .github/workflows/terraform-security-scan.yml
name: Terraform Security Scan

on:
  pull_request:
    paths:
      - 'terraform/**'
  push:
    branches: [main]

jobs:
  rego-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Setup OPA
        run: |
          curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
          chmod +x opa
          sudo mv opa /usr/local/bin/

      - name: Terraform Plan
        working-directory: terraform
        run: |
          terraform init -backend=false
          terraform plan -out=tfplan.binary
          terraform show -json tfplan.binary > tfplan.json

      - name: OPA Security Scan
        id: opa-scan
        continue-on-error: true  # Advisory mode - don't fail build yet
        run: |
          opa eval \
            --data policies/azure-storage-misconfigurations.rego \
            --input terraform/tfplan.json \
            --format pretty \
            'data.azure.storage.deny' > violations.json

          # Get violation count
          VIOLATIONS=$(opa eval \
            --data policies/azure-storage-misconfigurations.rego \
            --input terraform/tfplan.json \
            --format raw \
            'data.azure.storage.violation_summary.total_violations')

          echo "violations=$VIOLATIONS" >> $GITHUB_OUTPUT

      - name: Comment PR with Results
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const violations = fs.readFileSync('violations.json', 'utf8');
            const count = '${{ steps.opa-scan.outputs.violations }}';

            const body = `## ⚠️ Terraform Security Scan Results

            **Violations Found**: ${count}

            <details>
            <summary>View Violations</summary>

            \`\`\`json
            ${violations}
            \`\`\`

            </details>

            > **Note**: Currently in advisory mode - this is not blocking your PR.
            > Enforcement begins [DATE]. Please remediate HIGH severity violations.
            `;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: body
            });
```

**Terraform Cloud Run Task Implementation**:

1. **Create Terraform Cloud Integration**:
   - Go to Terraform Cloud → Settings → Run Tasks
   - Create webhook endpoint (Lambda/Cloud Function)
   - Configure to receive `post-plan` events

2. **Run Task Lambda Function**:
   ```python
   import json
   import subprocess

   def lambda_handler(event, context):
       # Download Terraform plan JSON from TFC
       plan_json = download_plan(event['plan_json_api_url'])

       # Run OPA scan
       result = subprocess.run([
           'opa', 'eval',
           '--data', 'azure-storage-misconfigurations.rego',
           '--input', 'plan.json',
           '--format', 'json',
           'data.azure.storage'
       ], capture_output=True)

       violations = json.loads(result.stdout)

       # Return to Terraform Cloud (advisory mode)
       return {
           'data': {
               'type': 'task-results',
               'attributes': {
                   'status': 'passed',  # Advisory mode
                   'message': f"Found {len(violations)} violations (advisory)",
                   'url': 'https://your-dashboard/scan-results'
               }
           }
       }
   ```

**Actions**:
- Deploy GitHub Actions workflow to 2-3 pilot repositories
- Monitor for 2 weeks
- Collect feedback from development teams
- Fix any REGO policy bugs or false positives

**Deliverables**:
- ✅ Scans running on every PR (warnings only)
- ✅ Developers familiar with violation format
- ✅ < 10% false positive rate
- ✅ Updated REGO policies based on feedback

---

### Phase 3: Enforcement Mode (Week 5)

**Goal**: Block deployments with HIGH severity violations

**Configuration Changes**:

```yaml
# GitHub Actions - Update to blocking mode
- name: OPA Security Scan
  id: opa-scan
  run: |
    # Get HIGH severity count
    HIGH_VIOLATIONS=$(opa eval \
      --data policies/azure-storage-misconfigurations.rego \
      --input terraform/tfplan.json \
      --format raw \
      'count([v | v := data.azure.storage.deny[_]; v.severity == "HIGH"])')

    echo "high_violations=$HIGH_VIOLATIONS" >> $GITHUB_OUTPUT

    # Fail if HIGH severity violations found
    if [ "$HIGH_VIOLATIONS" -gt 0 ]; then
      echo "❌ Found $HIGH_VIOLATIONS HIGH severity violations"
      echo "Deployment blocked - remediate before merging"
      cat violations.json
      exit 1
    fi
```

**Terraform Cloud Run Task - Update to blocking**:
```python
# Return blocking status for HIGH severity
if high_severity_count > 0:
    return {
        'data': {
            'attributes': {
                'status': 'failed',  # NOW BLOCKING
                'message': f"❌ Found {high_severity_count} HIGH severity violations",
                'url': 'https://your-dashboard/scan-results'
            }
        }
    }
```

**Communication Plan**:
1. **2 weeks before enforcement**: Email all dev teams
   - "Enforcement starts [DATE]"
   - Link to documentation
   - Office hours for questions

2. **1 week before enforcement**: Slack announcement
   - Show example violations
   - How to fix common issues
   - Escalation path if blocked

3. **Day of enforcement**: Monitor closely
   - On-call security engineer for immediate support
   - Track blocked PRs
   - Fast-track REGO updates if needed

**Actions**:
- Enable enforcement on pilot repositories first
- Monitor for 1 week
- Roll out to remaining repositories gradually (10% per day)

**Deliverables**:
- ✅ HIGH severity violations block deployments
- ✅ < 2% legitimate blocks (false positives)
- ✅ Average remediation time < 1 hour
- ✅ Developer satisfaction score > 7/10

---

### Phase 4: Expansion (Weeks 6-12)

**Goal**: Extend to other Azure resources and refine policies

**Priority 1: Additional Azure Resources**
1. **Virtual Machines** (AVD-AZU-0030, AVD-AZU-0036)
   - Disk encryption
   - No public IPs
   - Managed identities

2. **Virtual Networks** (AVD-AZU-0047)
   - Network Security Groups attached
   - No overly permissive rules (0.0.0.0/0)

3. **Key Vaults** (AVD-AZU-0013)
   - Soft delete enabled
   - Purge protection enabled
   - Private endpoints

4. **SQL Databases** (AVD-AZU-0026)
   - TDE enabled
   - Auditing enabled
   - No public access

**Priority 2: REGO Policy Enhancements**
1. **Exception Handling**
   ```rego
   # Allow exceptions via Terraform tags
   deny[res] {
       resource := input.configuration.root_module.resources[_]
       # ... checks ...

       # Skip if exempted
       not has_exemption(resource, "enable-geo-redundant-backups")
   }

   has_exemption(resource, check_id) {
       tags := resource.expressions.tags.constant_value
       exemption := tags["security_exemption"]
       exemption == check_id
   }
   ```

2. **Custom Severity for Environments**
   - Dev: Advisory only
   - Test: Block HIGH
   - Prod: Block HIGH + MEDIUM

3. **Integration with Jira/ServiceNow**
   - Auto-create tickets for MEDIUM violations
   - Track remediation progress

**Priority 3: Reporting Dashboard**
- Weekly violation trends
- Top violated policies
- Team/repository breakdown
- Mean time to remediation

**Actions**:
- Expand REGO policies (1 new resource type per week)
- Build reporting dashboard (Grafana/Datadog)
- Integrate with ticketing system

**Deliverables**:
- ✅ REGO policies for 10+ Azure resource types
- ✅ Exception handling framework
- ✅ Reporting dashboard live
- ✅ Automated ticket creation

---

## 📋 BAU Operating Model (Steady State)

### Daily Operations

**Automated**:
- ✅ Scans run on every Terraform PR
- ✅ HIGH violations block automatically
- ✅ Results posted to PR comments
- ✅ Metrics collected to dashboard

**Manual**:
- Security engineer reviews MEDIUM violations weekly
- Platform team updates REGO policies monthly
- Quarterly review of exemptions

### Roles & Responsibilities

| Role | Responsibility | Time Commitment |
|------|---------------|-----------------|
| **Platform Engineering Team** | Maintain REGO policies, OPA infrastructure | 4 hours/week |
| **Security Team** | Review violations, approve exemptions | 2 hours/week |
| **Development Teams** | Remediate violations in their Terraform | As needed (avg 1 hour/month) |
| **On-Call Engineer** | Respond to false positive escalations | < 1 hour/week |

### Escalation Path

**Level 1: False Positive or Urgent Block**
- Developer opens Slack channel #security-rego-support
- Platform engineer responds within 2 hours
- Can temporarily disable check or grant exemption

**Level 2: Policy Change Needed**
- Create GitHub issue in `policies/` repo
- Security team reviews within 1 business day
- Platform team implements within 2 business days

**Level 3: Legitimate Business Need for Exemption**
- Developer fills out exemption request form
- Security team approves/denies within 3 business days
- Exemptions reviewed quarterly

### Success Metrics

**Security Metrics**:
- 📊 **Shift-Left Rate**: % of violations caught pre-deployment (Target: >90%)
- 📊 **Time to Production**: Average days from violation detected to remediated (Target: <3 days)
- 📊 **Production Security Gaps**: # of violations found by CloudSploit that REGO missed (Target: <5%)

**Operational Metrics**:
- 📊 **False Positive Rate**: % of blocks that were invalid (Target: <2%)
- 📊 **Developer Satisfaction**: Survey score 1-10 (Target: >7)
- 📊 **Policy Coverage**: % of CloudSploit checks covered by REGO (Target: >80%)

**Business Metrics**:
- 💰 **Remediation Cost Savings**: Time saved by catching issues pre-deployment
- 💰 **Incident Reduction**: # of security incidents related to storage misconfigurations
- 💰 **Compliance Score**: Azure CIS benchmark score improvement

### Maintenance Schedule

**Weekly**:
- Review violation dashboard
- Triage new false positives
- Update documentation

**Monthly**:
- Review and update REGO policies
- Add new CloudSploit checks
- Performance optimization

**Quarterly**:
- Review all exemptions (expire or renew)
- Developer feedback session
- Policy effectiveness review

**Annually**:
- Full audit of REGO policies
- Benchmarking against industry standards
- Strategic roadmap update

---

## 📚 Documentation & Training

### Developer Documentation

**Quick Start Guide** (`docs/terraform-security-scanning.md`):
- How REGO scanning works
- Common violations and how to fix
- How to request exemptions
- FAQ

**Remediation Playbook** (`docs/remediation-guide.md`):
- For each check: what it means, why it matters, how to fix
- Example Terraform code (before/after)
- Links to Azure documentation

### Training Plan

**Week 1**: Kickoff email
- Overview video (5 min)
- Link to documentation
- Office hours schedule

**Week 2-4**: Office hours
- 3x per week, 30 min sessions
- Live demo of REGO scanning
- Q&A

**Ongoing**:
- New hire onboarding includes REGO section
- Quarterly "lunch & learn" sessions
- #security-rego Slack channel for questions

---

## 🎯 Implementation Timeline Summary

| Phase | Duration | Status | Outcome |
|-------|----------|--------|---------|
| **Phase 1: POC** | Weeks 1-2 | Advisory | REGO validated in non-prod |
| **Phase 2: Advisory** | Weeks 3-4 | Warning only | Developers familiar with scans |
| **Phase 3: Enforcement** | Week 5 | Blocking HIGH | No HIGH violations reach Azure |
| **Phase 4: Expansion** | Weeks 6-12 | Scaling | 10+ resource types covered |
| **BAU: Steady State** | Ongoing | Optimizing | Continuous improvement |

---

## 💡 Pro Tips for Smooth Rollout

1. **Start Small**: Pilot with 2-3 friendly dev teams first
2. **Over-communicate**: Send updates weekly during rollout
3. **Be Available**: Extra office hours during enforcement phase
4. **Fast Feedback Loop**: Fix false positives within 2 hours
5. **Celebrate Wins**: Share metrics showing time/cost savings
6. **Iterate**: Update policies based on real-world feedback

---

## 📞 Support Contacts

- **Slack**: #security-rego-support
- **Email**: security-team@company.com
- **Documentation**: https://wiki.company.com/rego-scanning
- **On-Call**: PagerDuty "REGO Scanning" schedule

---

**Status**: Ready for Phase 1 implementation
**Next Review**: [2 weeks after Phase 1 starts]
**Owner**: Platform Engineering + Security Team
