# OpenCode Basic Agents Repository

This is an OpenCode agents registry repository containing agent definitions and configuration for the OpenCode AI coding assistant.

## Installation

Run the install script to install agents and subagents into `.opencode/`:

```bash
./install.sh
```

For CI/automation, use non-interactive mode:

```bash
./install.sh --non-interactive-agents    # Install agents only
./install.sh --non-interactive-all       # Install agents + other components
```

## Repository Structure

```
OpenNexus-Agents/
├── core/
│   ├── agents/
│   │   ├── primary/      # Primary agents (OpenCoder, OpenBrainstorm, etc.)
│   │   └── subagents/    # Subagents (deep-explorer, reviewer, tester, etc.)
│   ├── commands/         # Custom commands (installed into .opencode/commands)
│   └── skills/           # Reusable skill modules (installed into .opencode/skills)
├── .opencode/            # Installed agents (auto-generated, gitignored)
├── install.sh            # Installation script
├── registry.jsonc        # Component registry (JSONC with comments allowed)
└── opencode.jsonc        # Project config (optional, not required)
```

## Agent Definition Format

Agents are defined as Markdown files with YAML frontmatter. Example:

```markdown
---
description: Primary coding agent for implementation and refactors
mode: primary                     # "primary" or "subagent"
temperature: 0.2
tools:
  write: true
  edit: true
  bash: true
permission:
  bash:
    "*": allow
    "git push*": ask
  task:
    "*": deny
    "reviewer": allow
---
You are OpenCoder, the primary implementation agent.

Behavior guidelines...
```

### Frontmatter Format

Required fields: `description`, `mode` (primary/subagent), `temperature` (0.0-1.0), `tools` (write/edit/bash bools). Optional: `permission` for bash/task delegation.

Temperature guide: 0.0-0.2 precision (tester, reviewer), 0.2-0.4 coding (OpenCoder), 0.6-0.8 brainstorming (OpenBrainstorm).

Agent body (30-70 lines): mission, behavior guidelines, rules/limitations, delegation patterns, output format. Use bullets, stay concise, reference via `@agent-name`.

## Registry Format

`registry.jsonc` defines all components for installation. Each agent entry includes: `id`, `name`, `description`, `type`, `path`, `dependencies`, and `model-recommendation` mapping.

## Naming Conventions

### Agent IDs and Filenames
- Primary agents: lowercase with hyphens (`OpenCoder.md`, `OpenBrainstorm.md`)
- Subagents: lowercase with hyphens (`deep-explorer.md`, `junior-coder.md`)
- Filenames must match registry `id` field

### Agent Display Names
- PascalCase with spaces (`OpenCoder`, `Deep Explorer`)
- Be descriptive but concise

### Agent Categories

**Primary Agents** (user-facing, start conversations):
- `OpenNexus`: Orchestrator that delegates to specialists for best quality/speed/cost
- `OpenCoder`: Implementation, refactors, bug fixes
- `OpenBrainstorm`: Ideation, clarifying questions, exploring options
- `OpenPlanner`: Planning, analysis, step-by-step design

Primary-agent delegation policy: `OpenNexus` orchestrates via subagents by default. Other primary agents do not delegate unless explicitly asked.

**Subagents** (delegated by primary agents):
- `deep-explorer`: Read-only codebase discovery
- `designer`: UI/UX design and frontend polish
- `refactor-cleaner`: Dead code removal, duplication cleanup, dependency pruning
- `researcher`: Web research for official docs and GitHub examples
- `reviewer`: Read-only code review (correctness, security, maintainability)
- `tester`: Test/lint/build execution and triage
- `junior-coder`: Small, well-scoped edits (low-risk changes only)
- `senior-coder`: Complex refactors, multi-file changes, architecture
- `task-manager`: Task breakdown with sequencing, risks, acceptance criteria
- `context-manager`: Summaries and context pruning suggestions
- `requirement-manager`: Product requirements and tickets
- `doc-updater`: Documentation updates for recent changes
- `markdown-handler`: Markdown file creation and validation

## Dependency Management

Agents declare dependencies in `registry.jsonc`. Circular dependencies should be avoided. Typical dependency graph:

- Primary agents delegate to subagents
- `OpenCoder` delegates to: `deep-explorer`, `reviewer`, `tester`, `junior-coder`, `senior-coder`, `task-manager`
- `OpenBrainstorm` delegates to: `deep-explorer`, `reviewer`, `task-manager`, `requirement-manager`

## Bash Permission Guidelines

Set `ask` for destructive commands (`rm *`, `git push`, `docker *`, `kubectl *`, `terraform *`, publishing), system-level (`sudo *`), and unclear commands. Use `allow` for safe read commands (`git status`, `git diff`, `ls`). For `tester` subagent, allow: test commands `npm test*`, `pytest*`, `go test*`, `cargo test*`, `bun test*`, and lint/build.

## Agent Collaboration Patterns

Referencing other agents in agent bodies uses `@agent-name` syntax:

```markdown
- @subagent/deep-explorer for fast codebase discovery (read-only)
- @reviewer for review/risk analysis
- @tester to run and triage tests
- @junior-coder for narrow, well-scoped edits
- @senior-coder for complex refactors/multi-file work
```

## Skills

Skills are reusable instruction modules that provide domain-specific workflows. Located in `core/skills/` and installed to `.opencode/skills/`:

- `task-management`: Task management CLI for tracking and managing feature subtasks with status, dependencies, and validation
- `git-master`: Git operations including atomic commits, rebase/squash, history search (blame, bisect, log -S)
- `coding-standards`: Universal coding standards and best practices for TypeScript, JavaScript, React, and Node.js development
- `iterative-retrieval`: Pattern for progressively refining context retrieval to solve the subagent context problem

Each skill directory contains:
- `SKILL.md`: Main skill instructions and workflows
- `codemaps.md`: Code structure and implementation details

Skills are loaded via the `skill` tool and inject detailed instructions into the conversation context.

## Commands

Custom commands extend OpenCode functionality. Located in `core/commands/` and installed to `.opencode/commands/`:

- `checkpoint`: Save verification state and progress checkpoint
- `implement-plan`: Implement a saved plan from .opencode/plans/
- `update-init`: Scan project and update AGENTS.md
- `refactor-clean`: Remove dead code and consolidate duplicates
- `code-review`: Review code for quality, security, maintainability
- `orchestrate`: Orchestrate multiple agents for complex tasks
- `update-docs`: Update documentation for recent changes
- `format-files`: Format files using OpenCode formatters
- `learn`: Extract patterns and learnings from current session
- `add-skill`: Create a new skill doc under .opencode/skills/
- `create-jira-ticket`: Create a new Jira ticket from task requirements

Commands are invoked via the OpenCode CLI or within agent workflows.

## Testing Agents

There is no automated test suite for agent definitions. To verify changes:

1. Review the agent's YAML frontmatter syntax (valid YAML, all required fields)
2. Check the registry entry matches the file path and id
3. Run `./install.sh --non-interactive-agents` to verify installation
4. Test in OpenCode by invoking the agent and observing behavior

## Modifying This Guide

When updating AGENTS.md, keep it concise. This file should serve as quick reference for anyone working with or extending these agents.
