---
description: Scan the project and update AGENTS.md for OpenCode
agent: opencoder
---

# Update Init

This is the "update" version of OpenCode's `init`: scan the project and regenerate/refresh `AGENTS.md` so OpenCode can navigate the project better.

## What To Do

1. Scan the project at the repo root to understand what it is and how it is used.
2. Read `registry.jsonc` and `install.sh` to capture install behavior and available components.
3. Inspect source directories to reflect reality:
   - `core/agents/primary/`
   - `core/agents/subagents/`
   - `core/commands/`
   - `core/skills/`
4. Create or update `AGENTS.md` so it matches the latest project state:
   - What this repo is
   - How to install/use it (match `install.sh` defaults and flags)
   - Component registry overview (agents/subagents/commands/skills)
   - Conventions (agent frontmatter, naming, paths)
   - Any important workflow notes that help OpenCode operate in this repo

## Constraints

- Keep `AGENTS.md` concise and accurate; prefer facts derived from the repo over aspirational text.
- Preserve existing style and tone of `AGENTS.md`.
- Do not invent components; only document what exists in `registry.jsonc` and on disk.
- If inconsistencies exist between `registry.jsonc` and files, update `AGENTS.md` to describe reality and add a short "Mismatch" note at the end.

## Output

- Edit `AGENTS.md` in-place (or create it if missing) by delegating to @subagent/markdown-handler for proper markdown handling.
- After updating, briefly report what changed (1-5 bullets) and reference `AGENTS.md`.
