# Code Map: iterative-retrieval/ Skill

## Overview

The **Iterative Retrieval** skill provides a pattern for **progressively refining context retrieval** to solve the subagent context problem.

## Purpose

This skill addresses the challenge of:
- **Context limits**: LLMs have limited context windows
- **Information overload**: Too much context can be as bad as too little
- **Relevance**: Finding the most relevant code for a task
- **Efficiency**: Avoiding unnecessary file reads

## Key Capabilities

| Capability | Description |
|------------|-------------|
| **Progressive Refinement** | Start broad, narrow down based on findings |
| **Smart Search** | Use glob, grep, and read tools strategically |
| **Context Pruning** | Remove irrelevant information as focus sharpens |
| **Decision Points** | Know when you have enough context vs. need more |
| **Efficiency** | Minimize token usage while maximizing relevance |

## The Pattern

The iterative retrieval pattern follows these steps:

1. **Broad Search**: Use glob/grep to identify candidate files
2. **Shallow Read**: Read key sections to assess relevance
3. **Narrow Focus**: Identify the most relevant files/areas
4. **Deep Dive**: Read thoroughly only the relevant portions
5. **Validate**: Confirm you have sufficient context for the task

## When to Use

Load this skill when:
- Exploring an unfamiliar codebase
- Working with large codebases where full context won't fit
- Need to find specific implementations in many files
- Balancing thoroughness with context window limits
- Delegating to subagents with limited context

## Usage

```
skill: {"name": "iterative-retrieval"}
```

## Benefits

- **Solves subagent context problem**: Subagents get focused, relevant context
- **Reduces token usage**: Only read what's necessary
- **Improves accuracy**: More relevant context = better decisions
- **Scales to large codebases**: Works regardless of project size

## Relationships

- **Parent**: `core/skills/` directory
- **Used by**: `deep-explorer`, `context-manager`, all exploration tasks
- **Complements**: `context-manager` skill (for summarization)
- **Installed to**: `.opencode/skills/iterative-retrieval/`
