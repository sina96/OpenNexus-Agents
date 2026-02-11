---
description: Create a new skill doc under .opencode/skills/
agent: opencoder
subtask: true
---

# Add Skill

Create a new skill documentation file at `.opencode/skills/<skill-name>/SKILL.md`.

Input: $ARGUMENTS

## Requirements

1. Skill name comes from the first argument (`$1`).
2. Use remaining arguments as the skill topic/context (`$2..`). If none provided, infer topic from the repo context and the skill name.
3. Create the directory `.opencode/skills/$1/` (if missing).
4. The markdown-handler will create `.opencode/skills/$1/SKILL.md` with clear, reusable guidance and proper formatting.

## SKILL.md Template

Use this structure (keep it concise and action-oriented):

```markdown
# <Skill Name>

## Overview
<1-3 sentences: what this skill is and when to use it>

## Triggers
- <When to apply this skill>

## Process
1. <Step>
2. <Step>
3. <Step>

## Checks
- <Sanity checks / verification steps>

## Examples

### Good
<short example or snippet>

### Avoid
<anti-pattern>

## References
- <repo path(s) / command(s) / docs link(s) if applicable>
```

## Notes

- Prefer repo-specific conventions (naming, scripts, folder structure).
- Do not add secrets.
- Do not create a git commit unless explicitly asked.

## Delegation
This command uses @opencoder which delegates to @subagent/markdown-handler to ensure proper markdown formatting and frontmatter validation.
