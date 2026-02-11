---
description: Save verification state and progress checkpoint
agent: opencoder
subtask: true
---

# Checkpoint

Create a compact progress checkpoint for the current workspace. If `$ARGUMENTS` is provided, treat it as the checkpoint label/context.

Include (as available):

- Timestamp (UTC): !`date -u +"%Y-%m-%dT%H:%M:%SZ"`
- Repo/branch: !`git rev-parse --show-toplevel 2>/dev/null; git branch --show-current 2>/dev/null`
- HEAD: !`git log -1 --oneline --decorate 2>/dev/null`
- Recent commits: !`git log --oneline -10 2>/dev/null`
- Working tree: !`git status --porcelain=v1 2>/dev/null`
- Staged diff (stat): !`git diff --cached --stat 2>/dev/null`
- Unstaged diff (stat): !`git diff --stat 2>/dev/null`

Then run the fastest reasonable verification for this repo (tests/lint/build). Pick commands by inspecting the project (e.g. `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, etc.).

Output using this format:

## Checkpoint: <timestamp> - <label if any>

**Verification**
- Tests: <not run | passing | failing> (<command used>)
- Lint: <not run | passing | failing> (<command used>)
- Build: <not run | passing | failing> (<command used>)

**Changes**
- Summary: <1-3 bullets>
- Files touched: <top-level list>

**Failures / Risks**
- <bullets; include key error lines and suspected cause>

**Next Steps**
1. <next actionable step>
2. <next actionable step>

## After gathering the checkpoint**
- Suggest writing the checkpoint to a file if it would help future progress, but do not do it unless the user approves or explicitly asks.

### Optional saving checkpoint step (only if the user approves on asks for it)**
- Write the checkpoint into a file based on the user's preferred location.
- Default location: `[local opencode config directory]/docs/checkpoints`.
