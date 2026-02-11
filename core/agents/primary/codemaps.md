# Code Map: core/agents/primary/ Directory

## Overview

The `primary/` directory contains **user-facing conversation starter agents**. These are the agents that users interact with directly to begin AI-assisted coding sessions. They can delegate to subagents for specialized tasks.

## Primary Agents

| Agent | File | Temperature | Purpose |
|-------|------|-------------|---------|
| **OpenNexus** | `OpenNexus.md` | 0.2 | Orchestrator that delegates to specialists for optimal quality/speed/cost |
| **OpenCoder** | `OpenCoder.md` | 0.2 | Primary coding agent for implementation and refactors |
| **OpenBrainstorm** | `OpenBrainstorm.md` | 0.7 | Brainstorming agent for generating ideas and exploring options |
| **OpenPlanner** | `OpenPlanner.md` | 0.2 | Planning agent for analysis, design, and step-by-step plans |

## What Are Primary Agents?

Primary agents are:
- **User-facing**: Users start conversations with these agents
- **Conversation starters**: They handle the initial interaction and task understanding
- **Delegators**: They can delegate to subagents for specialized work (except OpenNexus which orchestrates by default)
- **High-level**: They focus on task comprehension and coordination

## Delegation Patterns

### OpenNexus (Orchestrator)
- **Default behavior**: Orchestrates via subagents
- **Delegates to**: All subagents including designer, researcher, senior-coder, etc.

### OpenCoder (Implementation)
- **Default behavior**: Does not delegate unless explicitly asked
- **Can delegate to**: `deep-explorer`, `reviewer`, `tester`, `junior-coder`, `senior-coder`, `task-manager`, `context-manager`, `markdown-handler`

### OpenBrainstorm (Ideation)
- **Default behavior**: Does not delegate unless explicitly asked
- **Can delegate to**: `deep-explorer`, `reviewer`, `task-manager`, `context-manager`

### OpenPlanner (Planning)
- **Default behavior**: Does not delegate unless explicitly asked
- **Can delegate to**: `deep-explorer`, `reviewer`, `task-manager`, `context-manager`, `markdown-handler`

## Relationships

- **Upstream**: `core/agents/` directory
- **Downstream**: Installed to `.opencode/agents/`
- **Peers**: Reference subagents in `../subagents/` via `@subagent/name` syntax
- **Configuration**: Model recommendations defined in `registry.jsonc`
