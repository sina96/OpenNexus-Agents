# Code Map: git-master/ Skill

## Overview

The **Git Master** skill provides comprehensive guidance for git operations. It is the authoritative reference for all git-related tasks and **MUST BE USED** for any git operations.

## Purpose

This skill ensures:
- **Atomic commits**: Each commit represents a single logical change
- **Clean history**: Proper use of rebase, squash, and history rewriting
- **History search**: Effective use of blame, bisect, and log search
- **Safe operations**: Proper handling of destructive commands
- **Consistent workflow**: Standardized git practices across all agents

## Key Capabilities

| Capability | Description |
|------------|-------------|
| **Atomic Commits** | Guidelines for creating focused, single-purpose commits |
| **Rebase/Squash** | Proper use of interactive rebase for history cleanup |
| **History Search** | Using `git blame`, `git bisect`, `git log -S` effectively |
| **Safety Protocols** | Rules for destructive operations (force push, reset, etc.) |
| **Commit Messages** | Standards for clear, informative commit messages |

## When to Use

**MUST** load this skill for:
- Any git commit operations
- Rebase or squash operations
- History investigation (blame, bisect)
- Branch management
- Push operations (especially force push)
- Merge conflict resolution

## Usage

```
skill: {"name": "git-master"}
```

## Safety Guidelines

The skill enforces:
- **Never** update git config
- **Never** run destructive commands without explicit user request
- **Never** skip hooks unless explicitly requested
- **Never** force push to main/master without warning
- **Ask** before: `rm *`, `git push`, `docker *`, `kubectl *`, `terraform *`, `sudo *`

## Relationships

- **Parent**: `core/skills/` directory
- **Used by**: All agents performing git operations
- **Complements**: `task-management` skill (for commit-per-task workflow)
- **Installed to**: `.opencode/skills/git-master/`
