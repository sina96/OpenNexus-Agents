# Code Map: task-management/ Skill

## Overview

The **Task Management** skill provides a CLI for tracking and managing feature subtasks with status, dependencies, and validation. It enables systematic breakdown of work into manageable, trackable units.

## Purpose

This skill helps agents and users:
- Break down complex features into subtasks
- Track task status (pending, in-progress, completed, blocked)
- Manage task dependencies
- Validate task completion against acceptance criteria
- Maintain visibility into project progress

## Key Capabilities

| Capability | Description |
|------------|-------------|
| **Task Breakdown** | Decompose features into executable subtasks |
| **Status Tracking** | Monitor task state throughout the workflow |
| **Dependency Management** | Define and track task prerequisites |
| **Acceptance Criteria** | Define clear completion standards |
| **Validation** | Verify tasks meet criteria before marking complete |

## When to Use

Load this skill when:
- Planning a complex multi-step feature
- Breaking down work into subtasks
- Tracking progress across multiple work items
- Managing dependencies between tasks
- Ensuring acceptance criteria are met

## Usage

```
skill: {"name": "task-management"}
```

## Relationships

- **Parent**: `core/skills/` directory
- **Used by**: `task-manager` subagent, planning workflows
- **Complements**: `git-master` skill (for commit-per-task workflow)
- **Installed to**: `.opencode/skills/task-management/`
