# Claude Agent Prompt: Update OPA REGO Policies to Modern Syntax

Use this prompt when you need to update REGO policies from older OPA versions to work with OPA 1.9+

---

## Prompt for Claude

```
I have a project that uses Open Policy Agent (OPA) with REGO policies written for older versions of OPA (pre-1.0).

I need to update all REGO policy files to be compatible with OPA 1.9+ which requires modern syntax with `if` and `contains` keywords.

Project location: [INSERT YOUR PROJECT PATH]

Please:

1. Find all REGO policy files (*.rego) in the project
2. Identify which files use the old syntax (rules without `if` keyword)
3. Update each file to use modern OPA 1.9+ syntax:
   - Change `deny[res] {` to `deny contains res if {`
   - Change helper functions from `function_name(param) {` to `function_name(param) if {`
   - Change `violation_summary = {` to `violation_summary := {`
   - Preserve all logic, comments, and functionality
4. Test the updated policies with OPA to ensure they work
5. Show me a summary of what was changed

Requirements:
- Use OPA 1.9+ modern syntax with `if` and `contains` keywords
- Maintain backward compatibility with the same input/output structure
- Keep all existing comments and metadata
- Ensure all rules still function identically

Example transformation:

OLD SYNTAX (OPA < 1.0):
```rego
deny[res] {
    resource := input.resources[_]
    resource.type == "bad_type"
    res := {"msg": "error"}
}

helper(x) {
    x == "value"
}
```

NEW SYNTAX (OPA 1.9+):
```rego
deny contains res if {
    resource := input.resources[_]
    resource.type == "bad_type"
    res := {"msg": "error"}
}

helper(x) if {
    x == "value"
}
```

Please proceed with the analysis and updates.
```

---

## Alternative Shorter Prompt

```
Update all REGO policy files in [PROJECT PATH] from old OPA syntax to OPA 1.9+ modern syntax.

Key changes needed:
- `deny[res] {` → `deny contains res if {`
- `function(x) {` → `function(x) if {`
- `variable = {` → `variable := {` (for assignments)

Preserve all logic and comments. Test with latest OPA version.
```

---

## What to Provide to Claude

1. **Project path** - Full path to your project directory
2. **OPA version** - Run `opa version` and include output
3. **Sample error** (if applicable) - Any OPA error messages you're seeing

---

## Expected Output from Claude

Claude should:

1. ✅ List all REGO files found
2. ✅ Show before/after diffs for each change
3. ✅ Test policies with `opa eval` or `opa test`
4. ✅ Confirm all policies work with OPA 1.9+
5. ✅ Provide summary of changes made

---

## Example Usage

**You say:**
```
I have a project at /Users/home/Developer/my-opa-project that uses OPA REGO policies.

I just upgraded OPA from 0.11.0 to 1.9.0 and now I'm getting errors like:
"rego_parse_error: `if` keyword is required before rule body"

Please update all REGO files to use modern OPA 1.9+ syntax.
```

**Claude will:**
1. Find all .rego files
2. Update syntax to OPA 1.9+
3. Test each policy
4. Commit changes
5. Provide summary

---

## Common OPA Syntax Changes

### Deny/Allow Rules
```rego
# OLD
deny[res] {
    condition
    res := {...}
}

# NEW
deny contains res if {
    condition
    res := {...}
}
```

### Helper Functions
```rego
# OLD
is_valid(x) {
    x == "valid"
}

# NEW
is_valid(x) if {
    x == "valid"
}
```

### Assignments
```rego
# OLD
summary = {
    "total": count(violations)
}

# NEW
summary := {
    "total": count(violations)
}
```

### Multiple Rule Definitions (OR logic)
```rego
# OLD
is_allowed(x) {
    x == "foo"
}
is_allowed(x) {
    x == "bar"
}

# NEW
is_allowed(x) if {
    x == "foo"
}
is_allowed(x) if {
    x == "bar"
}
```

---

## Validation Commands

After Claude updates the files, verify with:

```bash
# Check OPA version
opa version

# Test policies
opa eval --data policies/ --input test-input.json 'data.package.deny'

# Run unit tests (if you have them)
opa test policies/

# Lint policies
opa check policies/*.rego
```

---

## TF Static Scan Example (What We Did)

In the TF Static Scan project, Claude:

1. ✅ Updated `policies/azure-storage-misconfigurations.rego`
2. ✅ Changed all `deny[res] {` to `deny contains res if {`
3. ✅ Changed all helper functions to use `if` keyword
4. ✅ Changed `violation_summary = {` to `violation_summary := {`
5. ✅ Tested with OPA 1.9.0
6. ✅ Verified 27 violations still detected correctly

**Result:** Policy now works with latest OPA 1.9+ 🎉

---

## Tips for Success

✅ **Do:**
- Provide full project path
- Include OPA version info
- Share any error messages
- Let Claude test the changes

❌ **Don't:**
- Try to manually fix syntax (tedious and error-prone)
- Assume syntax is the only issue (OPA may have other breaking changes)
- Skip testing after updates

---

## Save This Prompt

Bookmark this file for future OPA updates in other projects!

**File location:** `/Users/home/Developer/tfscan/CLAUDE-PROMPT-OPA-UPDATE.md`
