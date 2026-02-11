---
description: Review code for quality, security, and maintainability
agent: reviewer
subtask: true
---

# Code Review

Review current changes for quality, security, and maintainability: $ARGUMENTS

## Context

- Branch: !`git branch --show-current 2>/dev/null`
- Status: !`git status --porcelain=v1 2>/dev/null`
- Changed files (unstaged): !`git diff --name-only 2>/dev/null`
- Changed files (staged): !`git diff --cached --name-only 2>/dev/null`
- Diff (stat): !`git diff --stat 2>/dev/null`
- Diff (staged stat): !`git diff --cached --stat 2>/dev/null`

If needed to assess correctness, inspect the actual diffs as well:

- Unstaged diff: !`git diff 2>/dev/null`
- Staged diff: !`git diff --cached 2>/dev/null`

## Review Checklist

Security (CRITICAL)

- Hardcoded secrets (keys/tokens/passwords)
- Injection risks (SQL/command/template)
- XSS risks and unsafe HTML
- Missing validation / authz checks
- Path traversal / SSRF / deserialization issues
- Unsafe crypto / insecure randomness

Code Quality (HIGH)

- Correctness edge cases and error handling
- Overly long functions/files, deep nesting
- Logging/telemetry leaks (PII), debug prints
- Missing tests for new/changed behavior

Maintainability (MEDIUM)

- Duplication, unclear abstractions, naming
- API design and backward compatibility
- Performance pitfalls (N+1, accidental quadratic loops)

Style (LOW)

- Formatting, lint issues, typing polish

## Output Format

For each issue:

**[SEVERITY]** path:line
Issue: <what>
Fix: <how>

Finish with:

- Decision: <block | recommend fixes | approve>
- Top 3 fixes to do next

IMPORTANT: Do not approve if CRITICAL/HIGH security issues exist.
