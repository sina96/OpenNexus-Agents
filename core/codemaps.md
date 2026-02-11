# Code Map: core/ Directory

## Overview

The `core/` directory is the **source of truth** for all OpenCode components. It contains the master copies of all agents, commands, and skills that get installed into the `.opencode/` directory by `install.sh`.

## Contents

### Subdirectories

| Directory | Description | Contents Count |
|-----------|-------------|----------------|
| `agents/` | Agent definitions | 4 primary + 13 subagents |
| `commands/` | Custom OpenCode CLI extensions | 10 commands |
| `skills/` | Reusable instruction modules | 4 skills |

## Structure

```
core/
├── agents/
│   ├── primary/           # User-facing conversation starters
│   │   ├── openjarvis.md
│   │   ├── opencoder.md
│   │   ├── openbrainstorm.md
│   │   └── openplanner.md
│   └── subagents/         # Specialized workers for delegation
│       ├── context-manager.md
│       ├── deep-explorer.md
│       ├── designer.md
│       ├── doc-updater.md
│       ├── junior-coder.md
│       ├── markdown-handler.md
│       ├── refactor-cleaner.md
│       ├── researcher.md
│       ├── reviewer.md
│       ├── requirement-manager.md
│       ├── senior-coder.md
│       ├── task-manager.md
│       └── tester.md
├── commands/
│   ├── checkpoint.md
│   ├── implement-plan.md
│   ├── update-init.md
│   ├── refactor-clean.md
│   ├── code-review.md
│   ├── orchestrate.md
│   ├── update-docs.md
│   ├── format-files.md
│   ├── learn.md
│   └── add-skill.md
└── skills/
    ├── task-management/
    ├── git-master/
    ├── coding-standards/
    └── iterative-retrieval/
```

## Installation Process

The `install.sh` script reads `registry.jsonc` and copies files from `core/` to `.opencode/`:

1. **Agents** → `.opencode/agents/` (primary) and `.opencode/agents/subagent/` (subagents)
2. **Commands** → `.opencode/commands/`
3. **Skills** → `.opencode/skills/`

## Relationships

- **Upstream**: Root directory (`install.sh`, `registry.jsonc`)
- **Downstream**: `.opencode/` receives installed copies
- **Peer**: Referenced by `registry.jsonc` for component metadata
- **Pattern**: All components follow consistent Markdown with YAML frontmatter format
