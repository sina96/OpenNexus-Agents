# Code Map: core/commands/ Directory

## Overview

The `commands/` directory contains **custom OpenCode CLI extensions**. These commands extend the OpenCode functionality and can be invoked via the OpenCode CLI or within agent workflows.

## Commands (11 Total)

### Development Workflow

| Command | File | Purpose | Dependencies |
|---------|------|---------|--------------|
| **checkpoint** | `checkpoint.md` | Save verification state and progress checkpoint | None |
| **implement-plan** | `implement-plan.md` | Implement a saved plan from `.opencode/plans/` | `opencoder` |
| **orchestrate** | `orchestrate.md` | Orchestrate multiple agents for complex tasks | `OpenNexus` |

### Code Quality

| Command | File | Purpose | Dependencies |
|---------|------|---------|--------------|
| **code-review** | `code-review.md` | Review code for quality, security, and maintainability | `reviewer` |
| **refactor-clean** | `refactor-clean.md` | Remove dead code and consolidate duplicates | `refactor-cleaner` |
| **format-files** | `format-files.md` | Format files using available OpenCode formatters | `junior-coder` |

### Documentation

| Command | File | Purpose | Dependencies |
|---------|------|---------|--------------|
| **update-docs** | `update-docs.md` | Update documentation for recent changes | `doc-updater` |
| **update-init** | `update-init.md` | Scan the project and update `AGENTS.md` for OpenCode | `opencoder` |
| **learn** | `learn.md` | Extract patterns and learnings from current session | `context-manager`, `markdown-handler` |

### Skills Management

| Command | File | Purpose | Dependencies |
|---------|------|---------|--------------|
| **add-skill** | `add-skill.md` | Create a new skill doc under `.opencode/skills/` | `opencoder` |

### Project Management

| Command | File | Purpose | Dependencies |
|---------|------|---------|--------------|
| **create-jira-ticket** | `create-jira-ticket.md` | Create a new Jira ticket from task requirements | `requirement-manager` |

## What Are Commands?

Commands are:
- **CLI Extensions**: Custom commands accessible via OpenCode CLI
- **Workflow Automation**: Encapsulate common multi-step operations
- **Agent-Delegating**: Many commands delegate to specialized agents
- **Reusable**: Can be invoked from agent workflows or manually

## Command Format

Commands are defined as Markdown files with YAML frontmatter:

```markdown
---
description: Brief description
mode: command
tools:
  bash: true | false
  # ... other tools
---

Command implementation details...
```

## Relationships

- **Upstream**: `core/` directory
- **Downstream**: Installed to `.opencode/commands/`
- **Dependencies**: Many commands depend on specific agents (declared in `registry.jsonc`)
- **Usage**: Invoked via OpenCode CLI or referenced in agent workflows
