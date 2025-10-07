# 🚀 START HERE - Quick Guide for New Claude Sessions

**When initializing a new Claude session in this project, do this:**

---

## Step 1: Share Context with Claude

**Copy and paste this into your first message:**

```
I'm working on the TFScan project at /Users/home/Developer/tfscan

Please read these files to understand the project:
1. CONTEXT.md - Complete project context and technical details
2. README.md - Project overview
3. docs/QUICK-START.md - Quick reference commands

This is a working project that uses REGO policies to detect Azure storage
misconfigurations in Terraform code before deployment (shift-left security).

All code is complete and tested. The project is ready for demo and pilot use.
```

---

## Step 2: Claude Will Understand

After reading those files, Claude will know:
- ✅ What the project does (shift-left CloudSploit findings)
- ✅ How it works (REGO scans Terraform plan JSON)
- ✅ What's implemented (6 CloudSploit checks, 27 violations detected)
- ✅ Where everything is (project structure)
- ✅ How to use it (commands, demo scripts)
- ✅ Technical details (OPA, REGO syntax, known issues)

---

## Step 3: Common Requests

**"Run the demo"**
```bash
cd /Users/home/Developer/tfscan
./tests/run-demo.sh
```

**"Test the REGO policy"**
```bash
cd /Users/home/Developer/tfscan
~/opa eval --data policies/azure-storage-misconfigurations.rego --input tfplan.json --format pretty 'data.azure.storage.deny'
```

**"Show me the violations summary"**
```bash
cd /Users/home/Developer/tfscan
~/opa eval --data policies/azure-storage-misconfigurations.rego --input tfplan.json --format pretty 'data.azure.storage.violation_summary'
```

**"Explain how the REGO policy works"**
→ Ask Claude to walk through `policies/azure-storage-misconfigurations.rego`
→ Reference: `docs/DEMO-GUIDE.md` has detailed explanations

**"Prepare me for a demo"**
→ Open `docs/DEMO-NARRATION.md` - Full script with talking points
→ Print `docs/DEMO-CHEAT-SHEET.md` - Keep next to keyboard

**"Add a new Azure resource type"**
→ Ask Claude to help extend the REGO policies
→ Reference: CONTEXT.md section "Extending This Project"

---

## 📁 Key Files Reference

| File | Purpose |
|------|---------|
| **CONTEXT.md** | Complete project context (read this first!) |
| **README.md** | Project overview and quick start |
| **PROJECT-SETUP.md** | Setup and migration notes |
| **policies/azure-storage-misconfigurations.rego** | The REGO policy |
| **examples/azure-storage-test.tf** | Test Terraform (27 violations) |
| **tests/run-demo.sh** | Interactive demo script |
| **docs/DEMO-NARRATION.md** | Demo script with talking points |
| **docs/DEMO-CHEAT-SHEET.md** | Printable reference for demos |
| **docs/QUICK-START.md** | Quick command reference |

---

## ✅ Quick Verification

**Verify project is ready:**
```bash
cd /Users/home/Developer/tfscan

# Should return: 27 violations (8 HIGH, 12 MEDIUM, 7 LOW)
~/opa eval --data policies/azure-storage-misconfigurations.rego --input tfplan.json --format pretty 'data.azure.storage.violation_summary'
```

If this works ✅ → Everything is ready!

---

## 💡 Pro Tips

1. **Always start at project root:** `cd /Users/home/Developer/tfscan`
2. **CONTEXT.md is your friend** - It has all the technical details
3. **Demo materials are complete** - Just follow the scripts
4. **OPA location:** `~/opa` (user home directory)
5. **Expected output:** 27 violations across 6 checks

---

## 🎯 What This Project Does (Quick Summary)

**Problem:** CloudSploit finds Azure storage issues AFTER deployment (1-2 week gap)

**Solution:** REGO policies scan Terraform BEFORE deployment (0-day gap)

**Status:** ✅ Complete, tested, ready for demo

**Coverage:** 6 CloudSploit checks (soft delete, geo-redundancy, encryption, logging)

---

**That's it! Claude now has full context. Ask away! 🚀**
