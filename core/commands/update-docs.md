---
description: Update documentation for recent changes
agent: doc-updater
subtask: true
---

# Update Docs

Update documentation to reflect recent changes: $ARGUMENTS

## Your Task

1. Identify changed code (staged + unstaged) via git
2. Find the minimal set of related docs (README, guides, command/agent docs)
3. Update docs so they match the actual implementation and current workflows
4. Ensure examples and commands shown are runnable from repo root

## Inputs

- Status: !`git status --porcelain=v1 2>/dev/null`
- Changed files (unstaged): !`git diff --name-only 2>/dev/null`
- Changed files (staged): !`git diff --cached --name-only 2>/dev/null`
- Diff (stat): !`git diff --stat 2>/dev/null`
- Diff (staged stat): !`git diff --cached --stat 2>/dev/null`

## Checklist

- README/setup is correct
- Command usage matches `core/commands/*` and registry ids
- Agent references (ids/names) match `registry.jsonc`
- Examples are up to date
- Avoid speculative docs; add a TODO note if something is unclear
