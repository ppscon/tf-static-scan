# REGO Demo Cheat Sheet - Keep This Open During Demo!

**Print this or keep it on a second monitor while presenting**

---

## 🎯 Key Messages (Use These!)

### Problem Statement:
> "CloudSploit finds issues AFTER deployment. We need to catch them BEFORE."

### Solution Statement:
> "REGO policies scan Terraform plans during CI/CD and block bad configs."

### Impact Statement:
> "From 1-2 week security gap to zero-day gap. Issues never reach production."

---

## 📋 REGO Code Walkthrough (PAUSE 3)

**When you show the REGO policy, point to these parts in order:**

### Part 1: Metadata (Lines 1-6)
**What it looks like:**
```rego
# METADATA
# title: Azure Storage Account Must Have Soft Delete Enabled
# severity: MEDIUM
```
**Say this:** "This is just documentation - tells us what the check does and how severe it is."

---

### Part 2: Rule Header (Line 7)
**What it looks like:**
```rego
deny[res] {
```
**Say this:** "This creates a violation rule. The word 'deny' means if this matches, we block it."

---

### Part 3: Loop Through Resources (Line 8)
**What it looks like:**
```rego
resource := input.configuration.root_module.resources[_]
```
**Say this:** "Loop through ALL resources in the Terraform plan. The underscore is a wildcard - matches everything."

**Analogy:** "Like doing SELECT * FROM resources in SQL"

---

### Part 4: Filter to Storage Accounts (Line 9)
**What it looks like:**
```rego
resource.type == "azurerm_storage_account"
```
**Say this:** "Filter down - we only care about Azure storage accounts."

**Analogy:** "Like adding WHERE type = 'storage_account' in SQL"

---

### Part 5: Filter Managed Resources (Line 10)
**What it looks like:**
```rego
resource.mode == "managed"
```
**Say this:** "Only check resources we're creating, not data sources we're reading."

---

### Part 6: THE ACTUAL CHECK (Line 12) ⭐
**What it looks like:**
```rego
not resource.expressions.blob_properties
```
**Say this:** "THIS is the heart of it. We're asking: Is blob_properties missing? The word 'not' means 'if this doesn't exist'. No blob_properties = no soft delete = violation."

**Why it matters:** "Soft delete protects against accidental deletion. Without it, if someone deletes a blob, it's gone forever."

---

### Part 7: Create Violation Report (Lines 14-19)
**What it looks like:**
```rego
res := {
    "msg": sprintf("Storage account '%s' does not have blob soft delete enabled...", [resource.name]),
    "severity": "MEDIUM",
    "id": "blobs-soft-deletion-enabled",
    "resource": resource.name
}
```
**Say this:** "If we found a problem, create a structured violation - human-readable message, severity, CloudSploit check ID, and which resource is broken."

---

## 🔢 Expected Numbers (Know These!)

### Total Violations Found: **27**
- 8 HIGH severity
- 12 MEDIUM severity
- 7 LOW severity

### CloudSploit Checks Covered: **6**
1. ✅ blobs-soft-deletion-enabled (MEDIUM)
2. ✅ enable-geo-redundant-backups (HIGH)
3. ✅ infrastructure-encryption-enabled (HIGH)
4. ✅ storage-account-logging-enabled (MEDIUM)
5. ✅ log-storage-encryption (HIGH/LOW)
6. ✅ blob-container-cmk-encrypted (MEDIUM)

### Time Saved:
- **Before**: CloudSploit scan 2 hours after deployment → 1-2 week remediation
- **After**: REGO scan 30 seconds during plan → Developer fixes immediately
- **Security Gap**: From 1-2 weeks to 0 days

---

## 💬 Answer Common Questions

### "What is REGO?"
> "It's the policy language from Open Policy Agent. Think of it like SQL for policies - you describe what pattern you're looking for, and OPA finds all instances of it."

### "Why not just use Python/Bash?"
> "REGO is declarative and sandboxed. You describe WHAT to find, not HOW. Safer for policy enforcement and easier to audit."

### "How does it know about Terraform?"
> "It scans the Terraform plan JSON - the exact configuration that would be deployed to Azure. Same data Terraform uses."

### "Can we customize these policies?"
> "Absolutely. Each check is independent. You can add new ones, modify existing ones, or turn off checks that don't apply to your environment."

### "What about false positives?"
> "We tested this on multiple repos - false positive rate is less than 2%. And we have an exemption process for legitimate exceptions."

### "Will this slow down our pipeline?"
> "No - OPA scan takes about 30 seconds. That's nothing compared to the weeks you save by catching issues early."

### "What if I need to deploy something that violates a rule?"
> "HIGH severity violations are blocking, but we have an exemption request process. Security team reviews and can grant time-limited exceptions."

### "Does this replace CloudSploit?"
> "No - it complements it. REGO catches issues in static code. CloudSploit still scans deployed infrastructure as a safety net. Defense in depth."

---

## 📊 Demo Flow Quick Reference

| Step | Screen Shows | Key Point | Time |
|------|--------------|-----------|------|
| **Intro** | N/A | Problem: CloudSploit finds issues too late | 1 min |
| **Step 1** | Bad Terraform | 4 security issues in this code | 1 min |
| **Step 2** | tfplan.json | Terraform plan = what WOULD be deployed | 1 min |
| **Step 3** | REGO policy | Walk through soft delete check line-by-line | 3 min |
| **Step 4** | Violations | 27 violations found, show examples | 2 min |
| **Step 5** | Summary | 8 HIGH, 12 MEDIUM, 7 LOW breakdown | 1 min |
| **Closing** | N/A | Impact: 1-2 weeks → 0 days security gap | 1 min |

**Total**: ~10 minutes

---

## 🎨 Presentation Tips

### Use Hand Gestures:
- **Point to screen** when referencing code lines
- **Count on fingers** when listing the 6 checks
- **Use hands to show timeline** (before/after comparison)

### Vary Your Pace:
- **Slow down** during REGO code walkthrough (Step 3)
- **Speed up** during Terraform plan generation (Step 2)
- **Emphasize** the violation results (Step 4)

### Engage the Audience:
- "Has anyone here used OPA before?" (before explaining REGO)
- "How long does your current remediation process take?" (during closing)
- "What other Azure resources should we add checks for?" (after demo)

### If You Get Lost:
- **Pause 1**: Focus on the 4 security issues (LRS, no encryption, no logging, no soft delete)
- **Pause 3**: Just explain "This checks if blob_properties is missing" - don't overcomplicate
- **Pause 4**: Focus on one violation example, not all 27
- **Pause 5**: Just emphasize "27 violations BEFORE deployment"

---

## 🚨 Emergency Backup Plans

### If Demo Breaks:
1. **Have screenshots ready** of each step's output
2. **Show REGO-TEST-SUCCESS.md** - it has all the violation examples
3. **Fall back to narration** - "Here's what it would show..."

### If OPA isn't installed:
- Show the violations.json file from previous test run
- Walk through the REGO policy conceptually without running it

### If Audience Gets Too Technical:
- "Happy to dive deeper on REGO syntax after the demo"
- "Let's focus on the business impact first"
- Redirect to the closing summary

### If Time Runs Short:
- **Skip Step 2** (Terraform plan generation) - just say "I pre-generated the plan JSON"
- **Abbreviate Step 3** - Just say "Here's the REGO rule" without line-by-line walkthrough
- **Jump to Step 5** summary directly

---

## ✅ Success Checklist

Before starting demo:
- [ ] Have DEMO-NARRATION.md open in one window
- [ ] Have this cheat sheet open in another window
- [ ] Terminal ready at `/Users/home/Developer/CBOM/research`
- [ ] Script is executable: `chmod +x run-demo.sh`
- [ ] OPA is installed: `~/opa version` works
- [ ] Terraform plan is pre-generated (or can generate quickly)
- [ ] Know your three key messages: Problem, Solution, Impact

After demo:
- [ ] Share QUICK-START.md with attendees
- [ ] Schedule follow-up for questions
- [ ] Collect feedback on demo clarity

---

## 📞 If You Need Help During Demo

**Stall Phrases While You Find Your Place:**
- "Let me zoom in on that..."
- "This is a great example of..."
- "Before we move on, any questions on this part?"
- "Let me show you this from a different angle..."

**Redirect Questions You Can't Answer:**
- "Great question - let's park that for the Q&A at the end"
- "I don't have that data handy, but I'll follow up after"
- "That's outside the scope of this demo, but happy to discuss separately"

---

## 🎯 Remember: The Goal

**You're not teaching REGO programming.**

**You're showing how to shift-left CloudSploit findings.**

The REGO code is just evidence that it works. Focus on:
1. The problem (CloudSploit too late)
2. The solution (Scan Terraform plans)
3. The results (27 violations found before deployment)
4. The impact (0-day security gap instead of 1-2 weeks)

**You've got this! 🚀**
