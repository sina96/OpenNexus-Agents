# Code Map: core/skills/ Directory

## Overview

The `skills/` directory contains **reusable instruction modules** that provide domain-specific workflows. Skills are loaded via the `skill` tool and inject detailed instructions into the conversation context.

## Skills (4 Total)

| Skill | Directory | Purpose |
|-------|-----------|---------|
| **Task Management** | `task-management/` | Task management CLI for tracking and managing feature subtasks |
| **Git Master** | `git-master/` | Git operations including atomic commits, rebase/squash, history search |
| **Coding Standards** | `coding-standards/` | Universal coding standards for TypeScript, JavaScript, React, Node.js |
| **Iterative Retrieval** | `iterative-retrieval/` | Pattern for progressively refining context retrieval |

## What Are Skills?

Skills are:
- **Instruction Modules**: Detailed domain-specific workflows
- **Reusable**: Can be loaded by any agent when needed
- **Context Injection**: Loaded via the `skill` tool to inject instructions
- **Specialized**: Focus on specific domains (git, coding standards, etc.)

## Skill Format

Each skill is a directory containing a `SKILL.md` file:

```
skills/
├── task-management/
│   └── SKILL.md
├── git-master/
│   └── SKILL.md
├── coding-standards/
│   └── SKILL.md
└── iterative-retrieval/
    └── SKILL.md
```

## Loading Skills

Skills are loaded using the `skill` tool:

```
skill: {"name": "git-master"}
```

When loaded, the skill content is injected into the conversation context, providing detailed instructions for that domain.

## Skill Content Structure

Each `SKILL.md` typically includes:
- Domain overview and principles
- Step-by-step workflows
- Best practices and patterns
- Common pitfalls to avoid
- Examples and references

## Relationships

- **Upstream**: `core/` directory
- **Downstream**: Installed to `.opencode/skills/`
- **Usage**: Loaded on-demand via `skill` tool by agents
- **Scope**: Domain-specific expertise available to all agents
