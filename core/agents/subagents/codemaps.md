# Code Map: core/agents/subagents/ Directory

## Overview

The `subagents/` directory contains **specialized worker agents** that are delegated by primary agents. These agents focus on specific tasks and are not meant to be invoked directly by users.

## Subagents (13 Total)

### Exploration & Analysis

| Agent | File | Purpose |
|-------|------|---------|
| **Deep Explorer** | `deep-explorer.md` | Read-only codebase explorer for locating files, flows, and dependencies |
| **Researcher** | `researcher.md` | Web research specialist for official docs, GitHub examples, and external references |
| **Context Manager** | `context-manager.md` | Produces compact summaries, context pruning suggestions, and handoff notes |

### Coding & Implementation

| Agent | File | Purpose |
|-------|------|---------|
| **Senior Coder** | `senior-coder.md` | Handles complex refactors, multi-file changes, and architecture-level implementation |
| **Junior Coder** | `junior-coder.md` | Implements small, well-scoped changes safely (low-risk edits only) |
| **Designer** | `designer.md` | UI/UX design and frontend polish |
| **Markdown Handler** | `markdown-handler.md` | Creates or updates markdown files and validates frontmatter YAML |

### Review & Quality

| Agent | File | Purpose |
|-------|------|---------|
| **Reviewer** | `reviewer.md` | Read-only code reviewer focused on correctness, security, and maintainability |
| **Tester** | `tester.md` | Runs tests/linters/builds and triages failures into actionable fixes |
| **Refactor Cleaner** | `refactor-cleaner.md` | Refactoring specialist for dead code removal, duplication cleanup, and dependency pruning |

### Planning & Management

| Agent | File | Purpose |
|-------|------|---------|
| **Task Manager** | `task-manager.md` | Breaks work into executable steps with sequencing, risks, and acceptance criteria |
| **Requirement Manager** | `requirement-manager.md` | Creates clear product requirements and tickets for Jira/Trello/GitHub Issues |
| **Doc Updater** | `doc-updater.md` | Updates project documentation to match code and behavior |

## What Are Subagents?

Subagents are:
- **Specialized**: Focus on one specific type of task
- **Delegated**: Called by primary agents, not directly by users
- **Efficient**: Lower temperature (0.0-0.2) for precision tasks
- **Composable**: Can be combined to handle complex workflows

## Temperature Guidelines

| Range | Use Case |
|-------|----------|
| 0.0-0.2 | Precision tasks (tester, reviewer, deep-explorer) |
| 0.2-0.4 | Coding tasks (junior-coder, senior-coder) |
| 0.6-0.8 | Creative tasks (brainstorming, design exploration) |

## Relationships

- **Upstream**: `core/agents/` directory
- **Downstream**: Installed to `.opencode/agents/subagent/`
- **Invoked by**: Primary agents using `@subagent/name` syntax
- **Dependencies**: Some subagents depend on others (e.g., `doc-updater` depends on `markdown-handler`)
