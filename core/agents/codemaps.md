# Code Map: core/agents/ Directory

## Overview

The `core/agents/` directory contains all agent definitions for the OpenCode AI coding assistant. Agents are the core AI workers that handle different aspects of software development tasks.

## Contents

### Subdirectories

| Directory | Description | Count |
|-----------|-------------|-------|
| `primary/` | User-facing conversation starter agents | 4 agents |
| `subagents/` | Specialized workers delegated by primary agents | 13 agents |

## Agent Definition Format

All agents are defined as **Markdown files with YAML frontmatter**:

```markdown
---
description: Brief description of the agent
mode: primary | subagent
temperature: 0.0-1.0
tools:
  write: true | false
  edit: true | false
  bash: true | false
permission:
  bash:
    "*": allow | ask | deny
---

Agent behavior guidelines...
```

### Required Frontmatter Fields

| Field | Description |
|-------|-------------|
| `description` | Brief description of agent's purpose |
| `mode` | `"primary"` or `"subagent"` |
| `temperature` | 0.0-0.2 (precision), 0.2-0.4 (coding), 0.6-0.8 (brainstorming) |
| `tools` | Boolean flags for write, edit, bash permissions |

### Optional Frontmatter Fields

| Field | Description |
|-------|-------------|
| `permission` | Fine-grained permissions for bash commands and task delegation |

## Naming Conventions

- **Filenames**: Lowercase with hyphens (e.g., `deep-explorer.md`, `OpenBrainstorm.md`)
- **IDs**: Must match filename without extension
- **Display Names**: PascalCase with spaces (defined in `registry.jsonc`)

## Relationships

- **Upstream**: `core/` directory
- **Downstream**: Installed to `.opencode/agents/` and `.opencode/agents/subagent/`
- **Dependencies**: Declared in `registry.jsonc` (circular dependencies should be avoided)
- **Delegation**: Primary agents reference subagents using `@subagent/name` syntax
